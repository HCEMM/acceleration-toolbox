## Containers

### Why Containers?

In bioinformatics, reproducibility is critical. Containers allow you to package software, dependencies, and environments into a single, portable unit that runs consistently across different systems.

In this workshop, we will use containers to build reproducible steps of a Nextflow pipeline.

We will focus on:

- **Docker** (most widely used)
- **Singularity / Apptainer** (commonly used on HPC systems)

### Key Concepts

- **Image**: A blueprint containing software and dependencies
- **Container**: A running instance of an image
- **Dockerfile**: A script used to build a Docker image

### Containers in Nextflow

Nextflow integrates seamlessly with containers. Each process in a pipeline can run in its own container, ensuring:

- Reproducibility
- Dependency isolation
- Portability across systems

Example (Nextflow process):

```groovy
process FASTQC {
    container 'your-dockerhub-username/fastqc:latest'
    """
    fastqc input.fastq
    """
}
```

-----------------
### Workshop Task: Build Your Own Container

You will work in groups. Each group will create a Docker container for one step of a typical RNA-seq workflow:

* Quality Control → FastQC
* Read Trimming → Trimmomatic / Cutadapt
* Alignment / Quantification → Salmon
* Differential Expression → R + DESeq2

Each group will:

- Write a Dockerfile
- Build the image
- Test the tool inside the container
- Share the image for use in a Nextflow pipeline

### Example 1: FastQC Container
```FROM ubuntu:22.04

RUN apt-get update && \
    apt-get install -y fastqc default-jre && \
    apt-get clean

WORKDIR /data

CMD ["fastqc", "--help"]
```
**Build and test:**
```
docker build -t fastqc:test .
docker run --rm fastqc:test
```

**Example 2: Trimming Container (Cutadapt)**
```
FROM python:3.10-slim

RUN pip install cutadapt

WORKDIR /data

CMD ["cutadapt", "--help"]
```

**Example 3: Salmon Container**
```FROM ubuntu:22.04

RUN apt-get update && \
    apt-get install -y wget tar && \
    wget https://github.com/COMBINE-lab/salmon/releases/latest/download/salmon-latest_linux_x86_64.tar.gz && \
    tar -xzf salmon-latest_linux_x86_64.tar.gz && \
    mv salmon-*/bin/salmon /usr/local/bin/ && \
    rm -rf salmon*

WORKDIR /data

CMD ["salmon", "--help"]
```

**Example 4: R + DESeq2 Container**
```FROM rocker/r-base:4.3.1

RUN apt-get update && \
    apt-get install -y libxml2-dev libcurl4-openssl-dev libssl-dev && \
    R -e "install.packages('BiocManager')" && \
    R -e "BiocManager::install('DESeq2')"

WORKDIR /data

COPY deseq2_script.R /data/

CMD ["Rscript", "deseq2_script.R"]
```
### Testing Your Container

> Run your container with mounted data:
```
docker run --rm -v $(pwd):/data your-image-name <command>
```
### Using Containers with Apptainer (HPC)

If Docker is not available (e.g., on a cluster), you can use Apptainer:
```
apptainer pull docker://your-dockerhub-username/fastqc:latest
apptainer exec fastqc_latest.sif fastqc --help
```
**Collaboration**
Each group should:

- Push their Dockerfile to GitHub
- Build and (optionally) upload the image to Docker Hub
- Document:
	- Tool version
	- Inputs/outputs
	- Example command

> At the end, we will combine all containers into a full Nextflow pipeline.