# Bioinformatics Containers

<img width="1024" height="536" alt="image" src="https://github.com/user-attachments/assets/7e4b714b-ee3a-4e26-bb8d-01bf8caa44f5" />

_credit:_ [_combell.com_](https://www.combell.com/en/blog/what-is-docker/)

## 1. Introduction to Containers

Software rarely works in isolation. Most applications depend on a particular operating system, system libraries, programming-language version, and additional packages. If any part of this environment differs between computers, the application may behave differently, or fail completely.

This leads to a familiar problem:

> It works on my computer, but not on yours.!

A **container** provides a portable and isolated environment in which an application can run. It packages the application together with the libraries, dependencies, and configuration required by that application.

Instead of recreating the software environment manually on every computer, we distribute the environment as a **container image**.

<img width="614" height="556" alt="image" src="https://github.com/user-attachments/assets/448da41e-46e6-4fbf-a4c6-294b2897498d" />

### Image and container

These two terms are related but not interchangeable:

- A **container image** is a packaged, read-only template containing the application and its software environment.
- A **container** is a running instance of that image.

_A useful analogy is a recipe and a prepared meal:_

- The **image** is the recipe.
- The **container** is one meal prepared from that recipe.
- Multiple containers can be created from the same image.

<img width="300" alt="image" src="https://github.com/user-attachments/assets/d14cc0ed-43c7-44f6-8bfe-d3437963d3a1" />


### Containers compared with virtual machines

Containers and virtual machines both provide isolated environments, but they work differently.

| Feature | Container | Virtual machine |
|---|---|---|
| Contains | Application and dependencies | Complete operating system |
| Typical size | Megabytes to a few gigabytes | Several gigabytes or more |
| Startup time | Usually seconds | Often longer |
| Resource usage | Relatively lightweight | More resource-intensive |
| Isolation | Process-level | Full machine-level |

A container shares the host system's kernel, which makes it more lightweight than a complete virtual machine. However, a container is not simply a compressed folder: it must be executed by a compatible container runtime.

<img width="958" height="619" alt="image" src="https://github.com/user-attachments/assets/649b5af9-b84d-441c-8ee3-cb917b2532a5" />

_credit:_ [_pagetree.com_](https://pagertree.com/learn/docker/overview#what-is-docker)

### Why containers matter in bioinformatics

Bioinformatics analyses often combine many tools developed independently. A single workflow may require Python, R, Java, command-line utilities, and multiple system libraries—sometimes with conflicting version requirements.

Containers allow each analysis step to use its own predefined software environment.

- **Dependency isolation:** Tools requiring different software versions do not interfere with one another.
- **Portability:** The packaged environment can move between compatible computing platforms.
- **Reproducibility:** Researchers can record and reuse the software environment associated with an analysis.
- **Simpler installation:** Users do not need to install every analysis tool directly on the host system.
- **Scalability:** Containers can be integrated into workflows running on workstations, HPC clusters, and cloud platforms.

> **Important:** Containers capture the software environment, but they do not guarantee complete reproducibility. Input data, reference files, parameters, pipeline versions, random seeds, and relevant hardware details must also be recorded.

In this workshop, we will use containers to package the tools used by an RNA-seq workflow. We will then connect these containers to individual processes in a Nextflow pipeline.

---

## 2. Key Container Concepts

Before building or running a container, it is important to distinguish the main components of the container ecosystem.

- **Container image:** A packaged, read-only template containing an application and its software environment.
- **Container:** A running instance of an image.
- **Dockerfile:** A text file containing instructions for building an OCI-compatible container image.
- **Container runtime:** Software that retrieves images and starts containers, such as Docker or Apptainer.
- **Container registry:** An online service used to store and distribute images.
- **Image tag:** A human-readable label identifying a particular image version.
- **Image digest:** An immutable identifier calculated from the image contents.

A typical container workflow looks like this:

```text
Dockerfile → Container image → Registry → Running container
```

<img width="1000" alt="Container images being distributed through an online registry" src="https://github.com/user-attachments/assets/0d7ffc96-c457-4631-b3cb-e7d332f6d2c8" />

### Container registries

Container images are commonly distributed through public registries:

- [Docker Hub](https://hub.docker.com/) stores official, community, and user-created images.
- [Quay.io](https://quay.io/) hosts many scientific container images, including [BioContainers](https://biocontainers.pro/).

A complete image reference usually follows this pattern:

```text
registry/namespace/image:tag
```

For example:

```text
quay.io/biocontainers/samtools:1.20--h50ea8bc_0
```

This reference contains:

| Component | Value |
|---|---|
| Registry | `quay.io` |
| Namespace | `biocontainers` |
| Image | `samtools` |
| Tag | `1.20--h50ea8bc_0` |

> **Reproducibility tip:** Avoid unversioned or `latest` tags in scientific workflows. A versioned tag is better, while an image digest provides the strongest record of the exact image contents.



### Check your understanding

> Question 2.1. What is the difference between an image and a container?

> Question 2.2. What information does an image tag provide?

> Question 2.3. Why is `latest` a poor choice for a reproducible analysis?

---

## 3. Basic Structure of a Dockerfile

A Dockerfile is a build recipe for a container image. Docker processes its instructions in order and creates a series of filesystem layers.

A simple Dockerfile might contain:

```dockerfile
FROM python:3.11-slim-bookworm

RUN python -m pip install --no-cache-dir "multiqc==1.21"

WORKDIR /data

CMD ["multiqc", "--help"]
```

The main Dockerfile instructions are described below.

### `FROM`: select a base image

`FROM` defines the starting point for a build stage:

```dockerfile
FROM ubuntu:24.04
```

Instead of beginning with a general-purpose operating-system image, it is often easier to select a base image that already provides the required programming environment.

> For a Python application:

```dockerfile
FROM python:3.11-slim-bookworm
```

> For an R application:

```dockerfile
FROM rocker/r-ver:4.3.3
```

> For a Conda-based installation:

```dockerfile
FROM continuumio/miniconda3:<version>
```

Choose a base image that is:

- maintained by a trusted publisher;
- compatible with the application;
- as small as practical;
- explicitly versioned; and
- suitable for the target CPU architecture.

> **Question 3.1:** Why might a `python:slim` image be preferable to a complete Ubuntu image?

> **Question 3.2:** How would you select an appropriate base image for a particular bioinformatics tool?

### `RUN`: execute build commands

`RUN` executes a command while the image is being built.

For example:

```dockerfile
RUN apt-get update && \
    apt-get install -y --no-install-recommends fastqc && \
    rm -rf /var/lib/apt/lists/*
```

For Debian- and Ubuntu-based images:

- run `apt-get update` and `apt-get install` in the same instruction;
- use `--no-install-recommends` when optional packages are unnecessary;
- remove package-index files from the same layer; and
- pin important package versions where possible.

The commands are connected with `&&` so that the build stops if an earlier command fails.

The directory `/var/lib/apt/lists/` contains package indexes downloaded by `apt-get update`. These files are not required to run the installed application, so removing them reduces the final image size.

> **Question 3.3:** Why should installation caches and temporary build files be removed?

> **Question 3.4:** Why must the cleanup happen in the same `RUN` instruction as the installation?

### `WORKDIR`: set the working directory

`WORKDIR` defines the default directory inside the container:

```dockerfile
WORKDIR /data
```

If the directory does not exist, Docker creates it. Subsequent `RUN`, `COPY`, and `CMD` instructions use this directory unless another path is specified.

> **Question 3.5:** What problems could occur if the working directory is not explicitly defined?

### `COPY`: add local files

`COPY` transfers files from the Docker build context into the image:

```dockerfile
COPY scripts/run_qc.sh /usr/local/bin/run_qc.sh
```

This is useful for adding version-controlled scripts and configuration files.

**Do not copy the following into an image**:

- raw sequencing data;
- passwords, tokens, or credentials;
- unnecessary build files; or
- sensitive configuration.

Use a `.dockerignore` file to exclude files that should not be included in the build context.

_Downloading files during a build is sometimes necessary. When doing so, use a versioned URL and verify the downloaded file with a checksum._

> **Question 3.6:** When should a file be copied from the repository, and when might downloading it during the build be appropriate?

### `ENV`: define environment variables

`ENV` defines variables that are available inside the image:

```dockerfile
ENV PATH="/usr/local/bin:${PATH}"
ENV LC_ALL=C
```

Common uses include:

- adding an executable directory to `PATH`;
- selecting a locale;
- configuring default application behavior; and
- preventing interactive package-installation prompts.

Setting `LC_ALL=C` can make text sorting and parsing behavior more consistent across systems. This is useful when bioinformatics tools depend on deterministic text ordering.

Never store passwords or access tokens in an `ENV` instruction because they may remain visible in the image metadata and build history.

> **Question 3.7:** Why can locale settings affect the reproducibility of text-processing commands?

### `CMD` and `ENTRYPOINT`

Both instructions influence what happens when a container starts, but they have different roles.

`CMD` defines a default command:

```dockerfile
CMD ["fastqc", "--version"]
```

The command can be replaced when the user supplies another command to `docker run`.

`ENTRYPOINT` defines a fixed executable:

```dockerfile
ENTRYPOINT ["fastqc"]
CMD ["--help"]
```

With this configuration, arguments supplied after the image name are passed to FastQC:

```bash
docker run --rm fastqc-image --version
```

For single-purpose command-line images, an `ENTRYPOINT` can provide a convenient interface. However, images intended for workflow managers should not depend on a tool-specific entry point.

> **Nextflow compatibility:** Nextflow executes generated task scripts with Bash. Images intended for Nextflow should provide `/bin/bash`, make the required tools available on `PATH`, and avoid forcing a tool such as FastQC through `ENTRYPOINT`.

> **Question 3.8:** When would a fixed `ENTRYPOINT` be useful, and why might it cause problems for a workflow manager?


---

## 4. Building and Running Containers: Docker and Apptainer

Docker and Apptainer (*formerly Singularity*) can execute much of the same packaged software, but they are commonly used in different environments.

| Feature | Docker | Apptainer |
|---|---|---|
| Typical environment | Workstation, CI system, or cloud | Shared HPC cluster |
| Native image format | OCI/Docker image layers | Singularity Image Format (`.sif`) |
| Common use in this workshop | Build and test images | Execute images on the HPC |
| Runtime user | Depends on Docker configuration | Normally the invoking HPC user |
| Image filesystem | Writable container layer | SIF image is read-only by default |

### Building and testing with Docker

On a computer with an approved Docker installation, build an image from a Dockerfile:

```bash
cd 02_Containers/seqkit_container

docker build \
    --tag seqkit-workshop:1.0 \
    .
```

Test the image:

```bash
docker run --rm seqkit-workshop:1.0 seqkit --help
```

If the exercise uses Docker Compose:

```bash
docker compose build
docker compose run --rm seqkit seqkit --help
```

> The `--rm` option removes the stopped container after the command finishes. It does not delete the image or any results written to a mounted host directory.

> **Question 4.1:** Why is `--rm` useful during repeated testing?

### Why is Docker usually unavailable on an HPC?

Traditional Docker installations use a background daemon that commonly operates with elevated privileges. Allowing unrestricted Docker use can therefore create security and administration problems on a shared cluster.

Rootless Docker modes exist, but many HPC centers still prohibit Docker and provide Apptainer instead.

Apptainer is designed for shared computing systems because it:

- does not require a permanently running daemon;
- can execute containers as the current user;
- uses read-only SIF images by default;
- integrates with batch schedulers; and
- can retrieve images from Docker-compatible registries.

### Running an OCI image with Apptainer

Apptainer can pull an image from Docker Hub or Quay.io and convert it into a local SIF file:

```bash
module load apptainer

apptainer pull seqkit.sif \
    docker://quay.io/biocontainers/seqkit:2.6.1--h9ee0642_0
```

Execute a command inside the image:

```bash
apptainer exec seqkit.sif seqkit version
```

The image was originally distributed using the OCI container ecosystem, but it can now be executed on the HPC without installing SeqKit directly.

### How will we build images during the workshop?

Since we do not have permission to run Docker on the HPC. We will therefore use an automated build workflow:

1. Write or modify a Dockerfile.
2. Commit the Dockerfile to the workshop repository.
3. Push it to the group's assigned Git branch.
4. Allow GitHub Actions to build the image.
5. Publish the completed image to Docker Hub.
6. Pull the image onto the HPC with Apptainer.
7. Test the tool as a normal HPC user.

```text
Dockerfile
    ↓
Git repository
    ↓
GitHub Actions
    ↓
Docker Hub
    ↓
Apptainer SIF image
    ↓
HPC execution
```

> **Workshop principle:** A successful CI build is not the final test. The image must also run correctly with Apptainer as a non-root user on the HPC.

---

## 5. Containers in Nextflow

Once the basic container workflow is understood, we can connect images to Nextflow processes.

Nextflow can assign a separate container image to each process. When the process runs, Nextflow retrieves the image if necessary, makes the task files available inside the container, executes the process script, and writes the results to the host filesystem.

```groovy
process FASTQC {
    tag "${reads.simpleName}"

    cpus 2

    container 'quay.io/biocontainers/fastqc:0.12.1--hdfd78af_0'

    input:
    path reads

    output:
    path '*_fastqc.html'
    path '*_fastqc.zip'

    script:
    """
    fastqc \
        --threads ${task.cpus} \
        ${reads}
    """
}
```

The `container` directive specifies which image provides FastQC. FastQC does not need to be installed directly on the host.

The container runtime can be selected using a Nextflow configuration profile:

```groovy
profiles {
    docker {
        docker.enabled = true
    }

    apptainer {
        apptainer.enabled = true
        apptainer.autoMounts = true
    }
}
```

Run with Docker on a workstation:

```bash
nextflow run main.nf -profile docker
```

Run the same workflow with Apptainer on the HPC:

```bash
nextflow run main.nf -profile apptainer
```

This separates the scientific workflow from the computing platform:

- The process defines **what should run**.
- The container defines **which software environment should be used**.
- The configuration defines **where and how the process should run**.





# Exercises

1. Pull your first BioContainer: biocontainers/samtools:1.20--h50ea8bc_1 (tip: to pull from dockerhub use docker://; to pull from quay use quay.io/biocontainers/)

2. Inspect a container, and enter it's filesystem

3. Pull a seqkit container, and run it to get stats on a FastQ file

4. Create a file, and print it from inside the container

5. Build an image from a Dockerfile, with bowtie2 available inside, and run it to explore its contents

- (tip) bowtie2 requires build-essential, zlib1g-dev, libtbb-dev, and libsimde-dev
- (tip) bowtie2 source code can be downloaded from GitHub
- (tip) bowtie2 can be compiled with make

6. Run the same image, but see a file from your own system





--------------
## Answers

2.1. What is the difference between an image and a container?

<details> <summary><b>Answer</b></summary>
A **container image** is a packaged, read-only template containing an application, its dependencies, and configuration. A **container** is a running instance created from that image.

Multiple independent containers can be started from the same image.
</details>
    
2.2. What information does an image tag provide?

<details> <summary><b>Answer</b></summary>
An image tag is a human-readable label used to identify a particular image variant or release, such as:

```text
samtools:1.20
```
Here, samtools is the image name and 1.20 is the tag. Tags frequently indicate a software version, build, operating-system variant, or architecture.
However, tags can be changed or reassigned by the image publisher. They do not necessarily identify immutable image contents.
</details>
    
2.3. Why is latest a poor choice for a reproducible analysis?

<details> <summary><b>Answer</b></summary>
The latest tag does not identify a fixed software version. A publisher can update it to point to a different image, causing the same command to retrieve different software at a later date.
Use a versioned tag for better reproducibility
</details>

3.1 Why is it better to use python:slim instead of full ubuntu? 

<details> <summary><b>Answer</b></summary>

Because python:slim:

is much smaller in size

contains only essential dependencies

reduces build time

reduces security vulnerabilities

is faster to transfer and deploy (important for HPC + CI)

👉 Ubuntu full images include many unnecessary packages that are not needed for bioinformatics pipelines.

</details>

3.2 How do you know which base image to use for your tool?
<details> <summary><b>Answer</b></summary>

You choose based on the tool ecosystem:

Python tools → python:* images

R tools → rocker/r-ver

Conda-based pipelines → continuumio/miniconda3

Prebuilt bioinformatics tools → biocontainers/*

👉 Rule of thumb:
Use the closest official ecosystem image to reduce installation complexity.

</details>

3.3 Why is it important to clean up the cache after installing packages?
<details> <summary><b>Answer</b></summary>

Because package managers store temporary files used only during installation.

Cleaning cache:

reduces image size significantly

removes unnecessary build artifacts

improves portability and download speed

👉 Especially important in HPC where storage + transfer matters.

</details>

3.4 Why do we delete /var/lib/apt/lists/*?
<details> <summary><b>Answer</b></summary>

Because it contains:

package index metadata used only during apt-get update

After installation, it is no longer needed.

👉 Removing it:

reduces image size

avoids stale package metadata

improves reproducibility of builds

</details>

3.5 What happens if you don’t set WORKDIR?
<details> <summary><b>Answer</b></summary>
The container uses / (root) as default working directory

files may be written in unexpected locations

relative paths may break scripts

👉 WORKDIR ensures predictable execution context.

</details>

3.6 Why is setting LC_ALL sometimes important in bioinformatics?
<details> <summary><b>Answer</b></summary>

Because locale settings affect:

string sorting

text parsing behavior

character encoding

Setting:

LC_ALL=C

ensures:

consistent ASCII-based sorting

reproducible output across systems

👉 Prevents subtle differences between environments.

</details>

3.7 When would ENTRYPOINT be better than CMD in a bioinformatics container?
<details> <summary><b>Answer</b></summary>

Use ENTRYPOINT when:

the container is designed for one tool only

you want to enforce a fixed executable

you want consistent CLI behavior

Example:

ENTRYPOINT ["fastqc"]

👉 CMD is better when:

you want flexibility in overriding commands
</details>

4.1 Why is --rm useful when testing?
<details> <summary><b>Answer</b></summary>

Because it:

automatically deletes the container after execution

prevents accumulation of stopped containers

keeps the system clean during iterative testing

👉 Important for rapid debugging workflows.

</details>

5.1 What is the difference between image and container?
<details> <summary><b>Answer</b></summary>
Image = static blueprint (read-only template)
Container = running instance of that image

👉 Analogy:

Image = class definition
Container = object instance
</details>

5.2 Why do we need containers in HPC?
<details> <summary><b>Answer</b></summary>

Because HPC environments:

are shared between many users

do not allow root access (security)

require reproducible software environments

Containers solve this by:

packaging software + dependencies

running without root (Apptainer)

ensuring reproducibility across users

</details>

5.3 Why is reproducibility improved by containers?
<details> <summary><b>Answer</b></summary>

Because containers fix:

software versions

dependency versions

system libraries

environment configuration

👉 This ensures that the same pipeline produces the same results across machines and time.

</details>

5.4 What happens if two tools require different Python versions?
<details> <summary><b>Answer</b></summary>

Without containers:

dependency conflicts occur (“dependency hell”)

one tool overwrites the other’s environment

pipeline breaks

With containers:

each tool runs in isolated environment

no conflicts between versions

</details>

5.5 Could you fully reproduce a container without internet access?
<details> <summary><b>Answer</b></summary>

Yes, but only if:

all dependencies are already included in the image

no external downloads are required during build or runtime

If external sources are needed:

reproducibility fails without network access
</details>

5.6 What is the weakest point of container reproducibility?
<details> <summary><b>Answer</b></summary>

External dependencies outside the container:

package repositories (apt, CRAN, pip)

GitHub source code

online databases

remote downloads during build

👉 If those change or disappear, builds may break even if the container definition is unchanged.

</details>



------------------
|Previous|Home|Next|
|--------|----|----|
|[GitHub](../01_GitHub/README.md)|[Home](../README.md)|[Workflow Managers](../03_Workflow_Managers/README.md)
