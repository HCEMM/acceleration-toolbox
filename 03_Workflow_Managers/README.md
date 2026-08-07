# Workflow Managers in Bioinformatics

> Bioinformatics analyses rarely consist of a single command. A typical workflow may include quality control, trimming, alignment, quantification, statistical analysis, and visualization. Each step can use different software and may depend on files produced by an earlier step.
> A **workflow manager** coordinates these steps so that an analysis can be executed consistently and efficiently.

<img width="1879" height="713" alt="image" src="https://github.com/user-attachments/assets/ee59cbd1-a586-41fa-aae9-e83230d6ece2" />




### 1. Why Use a Workflow Managers?

For a small analysis, you might run several commands manually. As the analysis grows, this approach becomes difficult to track and easy to perform incorrectly.

Without automation,  you must remember:
- which command produced each file;
- which outputs are required by later steps;
- the correct execution order;
- which samples can be processed in parallel;
- which software versions and parameters were used; and
- which steps must be repeated after a failure or input change.
  
A shell script can run commands in a fixed order, but it does not automatically understand dependencies, schedule independent tasks, request HPC resources, or reuse completed work.

> A workflow manager allows you to define the steps and their relationships. It then determines when and where each task should run.

### Main benefits

**Automation:** The complete analysis can be launched with one command.
- **Dependency tracking:** A task starts only when its required inputs are available.
- **Parallel execution:** Independent samples or tasks can run simultaneously.
- **Failure recovery:** Valid completed work can be reused when a workflow is resumed.
- **Resource management:** Tasks can request appropriate CPUs, memory, and execution time.
- **Portability:** The same workflow can run locally, on an HPC, or on supported cloud platforms.
- **Software integration:** Each step can use a container or Conda environment.

-------------

### 2. Workflows as Graphs

A computational workflow can be represented as a **directed acyclic graph**, commonly called a **DAG**.

- A **node** represents a computational task.
- An **edge** represents a dependency or data passed between tasks.
- **Directed** means that data moves in a defined direction.
- **Acyclic** means that the dependencies cannot form an endless loop.

<img width="361" height="347" alt="image" src="https://github.com/user-attachments/assets/c14c2504-7789-4fc2-8b13-8d61a3c5ad31" />

**Consider a simple quality-control workflow:**

```
                      ┌──→ FastQC(sample_1) ──┐
FASTQ files ──scatter─┼──→ FastQC(sample_2) ──┼──gather──→ MultiQC
                      └──→ FastQC(sample_3) ──┘
```

> The FastQC tasks are independent, so they can run in parallel. MultiQC must wait because it requires the reports produced by FastQC.

From this graph, a workflow manager can determine:

1. which tasks are ready to run;
2. which tasks can run simultaneously;
3. which outputs must be passed downstream; and
4. which tasks may be reused after a failure.










### 3.3. Nextflow and Snakemake

While there are many workflow systems, Nextflow and Snakemake are the two dominant players in bioinformatics. Both ensure reproducibility and scale seamlessly from local machines to massive computing clusters. However, they approach pipeline building differently.

|<img width="568" alt="image" src="https://github.com/user-attachments/assets/471e9cf7-eb48-408f-b4c2-7b6466b2eeb9" />|<img width="568" height="174" alt="image" src="https://github.com/user-attachments/assets/f29d81dd-180c-45f4-a9d1-9e244ed5e54b" />|
|--------------------|------------------|

#### 3.3.1. Nextflow (Process-Oriented)

Nextflow is built around **processes** and **channels**. It focuses on how data flows from one step to the next. It has exceptionally strong native integration with container engines like Docker and Apptainer, making it ideal for scalable, production-level pipelines.

> The conceptual model: "Take this input → process it → send the output downstream."

#### 3.3.2. Snakemake (File-Oriented)

Snakemake is built around **rules** and **files**. It defines relationships between input and output files using pattern matching (wildcards). Because it is built on top of Python, its syntax feels highly natural to Python developers.

> The conceptual model: "To create this expected output file → run this rule on this input."

#### 3.3.3. Comparison Overview

| Feature        | Nextflow                  | Snakemake                |
|----------------|--------------------------|--------------------------|
| **Core unit**      | Process                  | Rule                     |
| **Focus**          | Data flow via channels                | File relationships via rules       |
| **Language**       | Groovy-based             | Python-based             |
| **Parallelism**    | Built-in (channels)      | Built-in (DAG)           |
| **Containers**     | Native & tightly integrated           | Supported                |
| **Conda**            | Supported                | Native & tightly integrated           |

### 3.4. Design Principles for Scalable Workflows

#### 3.4.1. Separation of Concerns

A robust workflow explicitly separates the science from the software engineering:
- Business Logic (The Science): Your individual scripts (Python, R, Bash) handle the actual computation and data manipulation.
- Execution Logic (The Pipeline): The workflow manager decides when, where, and how to run those scripts.

#### 3.4.2. The Scatter-Gather Pattern

This is a fundamental pattern for parallelizing data science workflows:
- Scatter: Split a large dataset into independent chunks (e.g., separating RNA-seq data by individual samples).
- Process: Run the identical analysis step on each chunk simultaneously in parallel.
- Gather: Combine the independent results back together for the final analysis.  

## Nextflow - Final Exercise

Create a process for seqkit to transform the fastq files to fasta format.

---

### Docker section

1. Create a DockerHub account;

2. Create a Dockerfile for seqkit (can combine with `conda install`);

3.  Compile the image on your machine;

4.  Push to Dockerhub (`docker login`, `docker push`)

---

### Nextflow section

1. Create the process `.nf` file with corresponding inputs/outputs, script and "save to output dir" directives;

2. Add the requirements for cpus and memory on the corresponding configuration;

3. Add to the config files for conda and container;

4. Execute and test it.

---

### GitHub section

1. Commit the changes to your repository;

2. Pull from HCEMM repo;

3. Try a merge, and fix the conflicts;

4. Do the pull request.

------------------
|Previous|Home|Next|
|--------|----|----|
|[Containers](../02_Containers/README.md)|[Home](../README.md)|[Nextflow](../04_Nextflow/README.md)
