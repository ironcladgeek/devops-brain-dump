import logging
import os
from datetime import datetime
from pathlib import Path

import numpy as np
import torch
import torch.distributed as dist
import torch.nn as nn
import torch.nn.functional as F
from torch.nn.parallel import DistributedDataParallel as DDP
from torch.utils.data import DataLoader, TensorDataset
from torch.utils.data.distributed import DistributedSampler


def setup_logger(rank, world_size):
    """Setup logger for each node"""
    log_dir = Path("/shared/logs/nodes")
    log_dir.mkdir(parents=True, exist_ok=True)

    # Create a logger for this node
    logger = logging.getLogger(f"node_{rank}")
    logger.setLevel(logging.INFO)

    # Create file handler
    fh = logging.FileHandler(log_dir / f"node_{rank}.log")
    fh.setLevel(logging.INFO)

    # Create formatter
    formatter = logging.Formatter("%(asctime)s - %(name)s - %(message)s")
    fh.setFormatter(formatter)

    # Add handlers
    logger.addHandler(fh)

    return logger


class SimpleModel(nn.Module):
    def __init__(self, input_size=20, hidden_size=100, num_classes=2):
        super().__init__()
        self.layer1 = nn.Linear(input_size, hidden_size)
        self.layer2 = nn.Linear(hidden_size, hidden_size)
        self.layer3 = nn.Linear(hidden_size, num_classes)

    def forward(self, x):
        x = F.relu(self.layer1(x))
        x = F.relu(self.layer2(x))
        return self.layer3(x)


def setup_distributed():
    """Initialize distributed training"""
    # Get world size and rank from Slurm
    world_size = int(os.environ["SLURM_NTASKS"])
    rank = int(os.environ["SLURM_PROCID"])
    local_rank = int(os.environ["SLURM_LOCALID"])
    node_name = os.environ["SLURMD_NODENAME"]

    # Check if CUDA is available
    if torch.cuda.is_available():
        device = torch.device(f"cuda:{local_rank}")
        torch.cuda.set_device(device)
    else:
        device = torch.device("cpu")
        print(f"CUDA is not available. Using CPU on rank {rank}")

    # Initialize process group
    dist.init_process_group(
        backend="nccl" if torch.cuda.is_available() else "gloo",
        init_method="env://",
        world_size=world_size,
        rank=rank,
    )

    return rank, world_size, device, node_name


def create_synthetic_dataset(num_samples=10000, input_size=20):
    """Create a synthetic dataset for demonstration"""
    X = np.random.randn(num_samples, input_size).astype(np.float32)
    y = (X.sum(axis=1) > 0).astype(np.int64)
    return torch.FloatTensor(X), torch.LongTensor(y)


def prepare_dataloader(rank, world_size, batch_size=32):
    """Prepare distributed dataloader"""
    # Create synthetic dataset
    X, y = create_synthetic_dataset()
    dataset = TensorDataset(X, y)

    # Create distributed sampler
    sampler = DistributedSampler(
        dataset, num_replicas=world_size, rank=rank, shuffle=True
    )

    # Create dataloader
    dataloader = DataLoader(
        dataset,
        batch_size=batch_size,
        sampler=sampler,
        num_workers=0,
        pin_memory=True if torch.cuda.is_available() else False,  # Set to False for CPU
    )

    return dataloader


def train_epoch(model, dataloader, optimizer, epoch, rank, device, logger, node_name):
    """Train for one epoch"""
    model.train()
    total_loss = 0
    correct = 0
    total = 0

    for batch_idx, (data, target) in enumerate(dataloader):
        # Move data to appropriate device
        data, target = data.to(device), target.to(device)

        optimizer.zero_grad()
        output = model(data)
        loss = F.cross_entropy(output, target)
        loss.backward()
        optimizer.step()

        total_loss += loss.item()
        pred = output.argmax(dim=1, keepdim=True)
        correct += pred.eq(target.view_as(pred)).sum().item()
        total += target.size(0)

        if batch_idx % 10 == 0:
            msg = (
                f"Node: {node_name} (Rank {rank}) - Epoch: {epoch}, "
                f"Batch: {batch_idx}, Loss: {loss.item():.4f}, "
                f"Acc: {100. * correct / total:.2f}%"
            )
            logger.info(msg)

    return total_loss / len(dataloader), 100.0 * correct / total


def main():
    # Initialize distributed setup
    rank, world_size, device, node_name = setup_distributed()

    # Setup logger
    logger = setup_logger(rank, world_size)
    logger.info(f"Starting training on node {node_name} with rank {rank}")
    logger.info(f"Device: {device}, World size: {world_size}")

    # Create necessary directories
    model_dir = Path("/shared/models")
    results_dir = Path("/shared/results")
    for d in [model_dir, results_dir]:
        d.mkdir(parents=True, exist_ok=True)

    # Initialize model and move to device
    model = SimpleModel().to(device)
    model = DDP(model)

    # Setup optimizer
    optimizer = torch.optim.Adam(model.parameters(), lr=0.001)

    # Prepare dataloader
    dataloader = prepare_dataloader(rank, world_size)
    logger.info(
        f"Node {node_name} (Rank {rank}): Dataloader prepared with {len(dataloader)} batches"
    )

    # Training loop
    num_epochs = 10
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    results_file = results_dir / f"distributed_training_results_{timestamp}.txt"

    # Log initial information
    logger.info(f"Node {node_name} (Rank {rank}): Starting training loop")

    # Training loop
    for epoch in range(num_epochs):
        # Set epoch for distributed sampler
        dataloader.sampler.set_epoch(epoch)

        # Train one epoch
        loss, acc = train_epoch(
            model, dataloader, optimizer, epoch, rank, device, logger, node_name
        )

        # Log results
        logger.info(
            f"Node {node_name} (Rank {rank}): Epoch {epoch} completed - "
            f"Loss: {loss:.4f}, Accuracy: {acc:.2f}%"
        )

        # Save results and checkpoint from rank 0 only
        if rank == 0:
            with results_file.open("a") as f:
                f.write(f"Epoch: {epoch}, Loss: {loss:.4f}, Accuracy: {acc:.2f}%\n")

            checkpoint = {
                "epoch": epoch,
                "model_state_dict": model.state_dict(),
                "optimizer_state_dict": optimizer.state_dict(),
                "loss": loss,
                "device": device.type,
            }
            torch.save(checkpoint, model_dir / f"model_checkpoint_epoch_{epoch}.pt")

    logger.info(f"Node {node_name} (Rank {rank}): Training completed")
    dist.destroy_process_group()


if __name__ == "__main__":
    main()
