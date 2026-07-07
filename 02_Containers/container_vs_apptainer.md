# Docker Containers and Apptainer

## Docker vs Apptainer in HPC

| Concept | Docker / OCI containers | Apptainer containers |
|---|---|---|
| Common use | Local development, CI, DockerHub builds | HPC execution |
| Image format | Docker/OCI image layers | Usually single `.sif` file |
| Build file | `Dockerfile` | Apptainer definition file: `.def` |
| Build command | `docker build` | `apptainer build` |
| Run command | `docker run` | `apptainer run` / `apptainer exec` |
| Registry | DockerHub, GHCR, Quay, etc. | Can pull from `docker://`, `oras://`, `library://`, etc. |
| Root/admin needed? | Usually Docker daemon requires elevated privileges | Usually runs unprivileged on HPC |
| HPC recommendation | Build elsewhere, do not run Docker daemon on shared cluster | Pull/run with Apptainer on the cluster |

In practice, the common workflow is:

```text
Write Dockerfile -> Build image with Docker or GitHub Actions -> Push to DockerHub -> Pull/run on HPC with Apptainer
```

---

## 2. Command comparison

### 2.1 Search images

Docker can search DockerHub directly from the command line:

```bash
docker search alpine
docker search rocker/r-ver
docker search hcemm/bioinfo-workshop
```

Apptainer can search Apptainer Library images, but for DockerHub images it is usually better to search with DockerHub web UI or `docker search`, then use the image through `docker://`:

```bash
apptainer search alpine
apptainer search library://alpine
```

For DockerHub images with Apptainer, use this syntax:

```bash
apptainer pull alpine_latest.sif docker://alpine:latest
apptainer pull fastqc.sif docker://hcemm/bioinfo-workshop:fastqc
```

---

### 2.2 Pull images

Docker:

```bash
docker pull alpine:latest
docker pull hcemm/bioinfo-workshop:fastqc
```

Apptainer:

```bash
apptainer pull alpine_latest.sif docker://alpine:latest
apptainer pull fastqc.sif docker://hcemm/bioinfo-workshop:fastqc
```

---

### 2.3 Run default command

Docker:

```bash
docker run --rm hcemm/bioinfo-workshop:fastqc
```

Apptainer:

```bash
apptainer run fastqc.sif
```

---

### 2.4 Execute a specific command inside the image

Docker:

```bash
docker run --rm hcemm/bioinfo-workshop:fastqc fastqc --version
docker run --rm hcemm/bioinfo-workshop:salmon salmon --version
```

Apptainer:

```bash
apptainer exec fastqc.sif fastqc --version
apptainer exec salmon.sif salmon --version
```

You can also execute directly from DockerHub without manually creating a `.sif` first:

```bash
apptainer exec docker://hcemm/bioinfo-workshop:fastqc fastqc --version
apptainer exec docker://hcemm/bioinfo-workshop:salmon salmon --version
```

---

### 2.5 Open an interactive shell

Docker:

```bash
docker run --rm -it hcemm/bioinfo-workshop:fastqc sh
```

For Ubuntu/Debian-based images:

```bash
docker run --rm -it hcemm/bioinfo-workshop:salmon bash
```

Apptainer:

```bash
apptainer shell fastqc.sif
apptainer shell docker://hcemm/bioinfo-workshop:fastqc
```

---

### 2.6 Bind/mount local data into the container

Docker uses `-v` or `--volume`:

```bash
mkdir -p data results

docker run --rm \
  -v "$PWD/data:/data" \
  -v "$PWD/results:/results" \
  hcemm/bioinfo-workshop:fastqc \
  fastqc /data/sample.fastq.gz -o /results
```

Apptainer uses `--bind` or `-B`:

```bash
mkdir -p data results

apptainer exec \
  --bind "$PWD/data:/data" \
  --bind "$PWD/results:/results" \
  fastqc.sif \
  fastqc /data/sample.fastq.gz -o /results
```

---

## 3. Full Docker workflow: FastQC + MultiQC container

This example builds a Docker image containing FastQC and MultiQC.

### 3.1 Create a project directory

```bash
mkdir -p fastqc_multiqc_container
cd fastqc_multiqc_container
```

---

### 3.2 Create the Dockerfile

Create a file named `Dockerfile`:

```dockerfile
# 1. Define the base image. We want a lightweight Linux distribution.
FROM alpine:latest

# 2. Set an environment variable for the FastQC version.
ENV FASTQC_VERSION=0.12.1

# 3. Install required system dependencies.
RUN apk add --no-cache \
    bash \
    openjdk17-jre \
    perl \
    wget \
    unzip \
    fontconfig \
    ttf-dejavu

# 4. Install MultiQC.
RUN apk add --no-cache \
    python3 \
    py3-pip \
    build-base \
    python3-dev \
    linux-headers

RUN pip install --break-system-packages multiqc

# 5. Download, extract, and configure FastQC.
RUN wget https://www.bioinformatics.babraham.ac.uk/projects/fastqc/fastqc_v${FASTQC_VERSION}.zip && \
    unzip fastqc_v${FASTQC_VERSION}.zip && \
    rm fastqc_v${FASTQC_VERSION}.zip && \
    chmod 755 /FastQC/fastqc && \
    ln -s /FastQC/fastqc /usr/local/bin/fastqc

# 6. Set the default working directory where users will mount their data.
WORKDIR /data

# 7. Set the default command that runs when the container starts.
CMD ["fastqc", "--help"]
```

---

### 3.3 Build the Docker image

```bash
docker build -t hcemm-fastqc-multiqc:0.12.1 .
```

Check that the image exists:

```bash
docker images | grep hcemm-fastqc-multiqc
```

---

### 3.4 Test FastQC inside Docker

```bash
docker run --rm hcemm-fastqc-multiqc:0.12.1 fastqc --version
```

Test MultiQC:

```bash
docker run --rm hcemm-fastqc-multiqc:0.12.1 multiqc --version
```

Open a shell inside the container:

```bash
docker run --rm -it hcemm-fastqc-multiqc:0.12.1 sh
```

Inside the container:

```bash
which fastqc
which multiqc
fastqc --version
multiqc --version
exit
```

---

### 3.5 Run FastQC on a tiny test FASTQ file

Create test input data or read a fastq file from the data directory:

```bash
mkdir -p data results

cat > data/test.fastq <<'EOF_FASTQ'
@read1
ACGTACGTACGT
+
FFFFFFFFFFFF
@read2
TGCATGCATGCA
+
FFFFFFFFFFFF
EOF_FASTQ
```

Run FastQC with Docker:

```bash
docker run --rm \
  -v "$PWD/data:/data" \
  -v "$PWD/results:/results" \
  hcemm-fastqc-multiqc:0.12.1 \
  fastqc /data/test.fastq -o /results
```

Check output:

```bash
ls -lh results
```

Run MultiQC on the FastQC result folder:

```bash
docker run --rm \
  -v "$PWD/results:/results" \
  hcemm-fastqc-multiqc:0.12.1 \
  multiqc /results -o /results
```

Check output:

```bash
ls -lh results
```

Expected output files include:

```text
test_fastqc.html
test_fastqc.zip
multiqc_report.html
multiqc_data/
```

---

### 3.6 Tag and push to DockerHub

Replace `your-dockerhub-username` with your real DockerHub username or organization name.

```bash
docker login

docker tag hcemm-fastqc-multiqc:0.12.1 your-dockerhub-username/fastqc-multiqc:0.12.1
docker tag hcemm-fastqc-multiqc:0.12.1 your-dockerhub-username/fastqc-multiqc:latest

docker push your-dockerhub-username/fastqc-multiqc:0.12.1
docker push your-dockerhub-username/fastqc-multiqc:latest
```

For the workshop repository, the equivalent image naming pattern is:

```bash
docker tag hcemm-fastqc-multiqc:0.12.1 hcemm/bioinfo-workshop:fastqc
docker push hcemm/bioinfo-workshop:fastqc
```

---

## 4. Run the Docker image on HPC with Apptainer

On the HPC login node:

```bash
ml apptainer
```

### 4.1 Run directly from DockerHub

```bash
apptainer exec docker://hcemm/bioinfo-workshop:fastqc fastqc --version
apptainer exec docker://hcemm/bioinfo-workshop:fastqc multiqc --version
```

For your own DockerHub image:

```bash
apptainer exec docker://your-dockerhub-username/fastqc-multiqc:0.12.1 fastqc --version
```

---

### 4.2 Pull Docker image as a local `.sif` file

```bash
apptainer pull fastqc_multiqc.sif docker://hcemm/bioinfo-workshop:fastqc
```

Or for your own DockerHub image:

```bash
apptainer pull fastqc_multiqc.sif docker://your-dockerhub-username/fastqc-multiqc:0.12.1
```

Check the file:

```bash
ls -lh fastqc_multiqc.sif
```

---

### 4.3 Run commands from the `.sif` image

```bash
apptainer exec fastqc_multiqc.sif fastqc --version
apptainer exec fastqc_multiqc.sif multiqc --version
```

Open an interactive shell:

```bash
apptainer shell fastqc_multiqc.sif
```

Inside the image:

```bash
which fastqc
which multiqc
exit
```

---

### 4.4 Run FastQC on data with Apptainer

Create test input data or read a fastq file from the data directory:
```bash
mkdir -p data results

cat > data/test.fastq <<'EOF_FASTQ'
@read1
ACGTACGTACGT
+
FFFFFFFFFFFF
@read2
TGCATGCATGCA
+
FFFFFFFFFFFF
EOF_FASTQ
```

Run FastQC:

```bash
apptainer exec \
  --bind "$PWD/data:/data" \
  --bind "$PWD/results:/results" \
  fastqc_multiqc.sif \
  fastqc /data/test.fastq -o /results
```

Run MultiQC:

```bash
apptainer exec \
  --bind "$PWD/results:/results" \
  fastqc_multiqc.sif \
  multiqc /results -o /results
```

Check output:

```bash
ls -lh results
```

---

## 5. Native Apptainer workflow: build a `.sif` from a `.def` file

This is an alternative workflow. Instead of writing a Dockerfile first, we write an Apptainer definition file.

Important HPC note:

- Building directly from a `.def` file may require `sudo` or `--fakeroot`, depending on cluster configuration.
- Running an existing `.sif` file normally does not require root.
- On many HPC systems, the recommended method is still: build Docker image elsewhere, then use `apptainer pull docker://...` on the cluster.

---

### 5.1 Create an Apptainer definition file

Create a file named `fastqc_multiqc.def`:

```def
Bootstrap: docker
From: alpine:latest

%labels
    Author HCEMM
    Description FastQC and MultiQC container for bioinformatics workshop

%post
    FASTQC_VERSION=0.12.1

    apk add --no-cache \
        bash \
        openjdk17-jre \
        perl \
        wget \
        unzip \
        fontconfig \
        ttf-dejavu \
        python3 \
        py3-pip \
        build-base \
        python3-dev \
        linux-headers

    pip install --break-system-packages multiqc

    wget https://www.bioinformatics.babraham.ac.uk/projects/fastqc/fastqc_v${FASTQC_VERSION}.zip
    unzip fastqc_v${FASTQC_VERSION}.zip
    rm fastqc_v${FASTQC_VERSION}.zip
    chmod 755 /FastQC/fastqc
    ln -s /FastQC/fastqc /usr/local/bin/fastqc

    mkdir -p /data

%environment
    export FASTQC_VERSION=0.12.1

%runscript
    if [ "$#" -eq 0 ]; then
        exec fastqc --help
    else
        exec "$@"
    fi
```

---

### 5.2 Build the Apptainer image

If your environment allows fakeroot:

```bash
apptainer build --fakeroot fastqc_multiqc.sif fastqc_multiqc.def
```

If you are on a machine where you have administrator access:

```bash
sudo apptainer build fastqc_multiqc.sif fastqc_multiqc.def
```

Check the image:

```bash
ls -lh fastqc_multiqc.sif
```

---

### 5.3 Run the Apptainer image

Run the default command from `%runscript`:

```bash
apptainer run fastqc_multiqc.sif
```

Execute a command:

```bash
apptainer exec fastqc_multiqc.sif fastqc --version
apptainer exec fastqc_multiqc.sif multiqc --version
```

Run on data:

```bash
mkdir -p data results

cat > data/test.fastq <<'EOF_FASTQ'
@read1
ACGTACGTACGT
+
FFFFFFFFFFFF
@read2
TGCATGCATGCA
+
FFFFFFFFFFFF
EOF_FASTQ

apptainer exec \
  --bind "$PWD/data:/data" \
  --bind "$PWD/results:/results" \
  fastqc_multiqc.sif \
  fastqc /data/test.fastq -o /results

apptainer exec \
  --bind "$PWD/results:/results" \
  fastqc_multiqc.sif \
  multiqc /results -o /results
```

---

## 6. Example Slurm job using Apptainer

Create a Slurm script named `run_fastqc_apptainer.sh`:

```bash
#!/bin/bash
#SBATCH --job-name=fastqc_test
#SBATCH --output=fastqc_test_%j.out
#SBATCH --error=fastqc_test_%j.err
#SBATCH --time=00:10:00
#SBATCH --cpus-per-task=2
#SBATCH --mem=2G

set -euo pipefail

ml apptainer

IMAGE="fastqc_multiqc.sif"
DATA_DIR="$PWD/data"
RESULTS_DIR="$PWD/results"

mkdir -p "$DATA_DIR" "$RESULTS_DIR"

apptainer exec \
  --bind "$DATA_DIR:/data" \
  --bind "$RESULTS_DIR:/results" \
  "$IMAGE" \
  fastqc /data/test.fastq -o /results

apptainer exec \
  --bind "$RESULTS_DIR:/results" \
  "$IMAGE" \
  multiqc /results -o /results
```

Submit:

```bash
sbatch run_fastqc_apptainer.sh
```

Check:

```bash
squeue -u "$USER"
ls -lh results
```

---

## 8. Common mistakes


### 8.1 Common mistakes

#### Mistake 1: Forgetting to bind data

Wrong:

```bash
apptainer exec fastqc_multiqc.sif fastqc /scratch/myfile.fastq.gz
```

Better:

```bash
apptainer exec \
  --bind /scratch:/scratch \
  fastqc_multiqc.sif \
  fastqc /scratch/myfile.fastq.gz
```

---

#### Mistake 2: Building directly on HPC when not allowed

On many HPC systems, users should not run Docker and may not be allowed to build Apptainer images from `.def` files.

Recommended:

```text
Build with Docker/GitHub Actions -> Push to DockerHub -> Pull with Apptainer on HPC
```

---

#### Mistake 3: Confusing image and container

```text
Image     = static blueprint, e.g. hcemm/bioinfo-workshop:fastqc
Container = running instance of that image
SIF       = Apptainer image file, e.g. fastqc_multiqc.sif
```

---

#### Mistake 4: Using latest everywhere

For learning, `latest` is convenient. For real reproducible pipelines, fixed versions are better:

```dockerfile
FROM ubuntu:22.04
ENV SALMON_VERSION=1.11.4
```

Better than:

```dockerfile
FROM ubuntu:latest
```

---

