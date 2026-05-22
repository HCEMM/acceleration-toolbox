## Bioinformatics Containers

### 1. Why Containers?

Have you ever tried to run a tool that worked perfectly on a colleague's laptop, only to face hours of installation errors on your own machine? This is the exact problem containers solve.

In bioinformatics, reproducibility is critical. A container is a standard unit of software that packages up code and all its dependencies so the application runs quickly and reliably from one computing environment to another.

In this workshop, we will use containers to build reproducible steps of a Nextflow pipeline.

Why are they useful?
- **Reproducibility**: A containerized pipeline run today will produce the exact same results 5 years from now.
- **Dependency Isolation**: Need a specific version for one tool? Containers keep their environments entirely separated.
- **Portability**: You can move the exact same environment from your laptop to a massive HPC cluster or the cloud.



### Containers in Nextflow

Nextflow integrates seamlessly with containers. Instead of installing tools locally, each process in a pipeline can spin up its own container, run the job, and shut down:

```{groovy}
process FASTQC {
    container 'your-dockerhub-username/fastqc:latest'
    
    script:
    """
    fastqc input.fastq
    """
}
```

### 2. Key conepts and the Docker Hub
- **Image**: A read-only blueprint containing the OS, software, and dependencies.
- **Container**: A running, active instance of an image.
- **Dockerfile**: A simple text script containing the instructions used to build an image.
- **Docker Hub**: Think of it as "GitHub for Docker images." It is a public registry where developers upload their built images so others can download (pull) and use them. [DockerHub](https://hub.docker.com)

<img width="1200" height="594" alt="image" src="https://github.com/user-attachments/assets/0d7ffc96-c457-4631-b3cb-e7d332f6d2c8" />

### 3. Basic Structure of a Dockerfile

A Dockerfile is built layer by layer using specific keywords:
- **FROM**: The starting point or base image (e.g., ubuntu:22.04 or python:3.10-slim). Every Dockerfile must start with a FROM statement.
- **RUN**: Executes terminal commands to install software or download files (e.g., RUN apt-get install -y wget).
- **WORKDIR**: Sets the working directory inside the container.
- **COPY**: Copies files from your local machine into the container.
- **CMD**: The default command the container runs if no other command is provided.

<img width="1184" height="831" alt="image" src="https://github.com/user-attachments/assets/2215ba89-df63-43b6-a8a8-818ebf3742f6" />

### 4. Building & Running: Docker vs. Apptainer (HPC)
**If you have Root privileges (e.g., on your personal laptop):**
You would typically build and test containers using Docker directly:
```
docker build -t my-tool:latest .
docker run --rm my-tool:latest
```

**Working on an HPC (Workshop Reality):** \
Docker requires root (administrator) privileges to run, which poses a massive security risk on shared High-Performance Computing (HPC) clusters. Therefore, HPCs use Apptainer (formerly named Singularity).

Apptainer can download and run Docker images without requiring root privileges.

The Problem: If we don't have root on the HPC, how do we build our Docker images?
> The Solution: We will write the code, push it to GitHub, and let an automated GitHub workflow build it and push it to Docker Hub for us!


------------------

### 5. Building Your Own Containers
You will work in groups. Each group is responsible for creating a working Docker container for one step of our RNA-seq workflow:
1. Quality control --> ```FastQC``` and ```MultiQC```
2. Read trimming --> ```trimmomatic```
3. Alignment + quantification (psueodalignment) --> ```Salmon```
4. Differential expression analysis --> ```R + limma```


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
