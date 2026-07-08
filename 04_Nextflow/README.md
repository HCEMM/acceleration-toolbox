## Nextflow

In previous sessions, we containerized individual bioinformatics tools. Here, we will integrate those tools into an automated, reproducible Nextflow workflow.

**The Objective**: Build a collaborative RNA-seq pipeline consisting of FastQC, Trimmomatic, Salmon, MultiQC, and R (Limma).

**The Workspace**: [```HCEMM/rnaseq-nextflow```](https://github.com/HCEMM/rnaseq-nextflow) repository (Groups 1-4).

<img width="517" height="561" alt="image" src="https://github.com/user-attachments/assets/29096289-52f6-4480-861f-dee23e09494b" />

*Source: [HBCTraining - Pseudoaligners](https://hbctraining.github.io/Intro-to-rnaseq-hpc-gt/lessons/10_salmon.html)*

-------------

### Part 1: Pipeline Architecture
A standard Nextflow repository relies on two central files to control execution and configuration, isolating the "how" from the "where."


Directory Overview:
- ```main.nf``` (The master script)
- ```nextflow.config``` (The settings)
- ```/processes``` (Where your individual group modules live)
- ```/data``` (Input datasets and references)
- ```/results``` (Where the final outputs will be saved)


### 1. ```nextflow.config``` (Infrastructure and Resources)

[nextflow.config](https://github.com/HCEMM/rnaseq-nextflow/blob/developer/nextflow.config) dictates execution rules: job scheduling, CPU/RAM allocation, and container integration.


### 2. ```main.nf``` (The Master Workflow)

[main.nf](https://github.com/HCEMM/rnaseq-nextflow/blob/developer/main.nf) orchestrates data flow using **Nextflow Channels**. It imports modules and wires tool outputs to downstream inputs.

----------------

### Part 2: Writing Nextflow Processes | Nextflow Directives & Data Types

**Example DAG architecture**

<img width="691" height="686" alt="flowchart" src="https://github.com/user-attachments/assets/78237e23-4b0c-42f4-bab8-e6e8cd9f037a" />


A Nextflow process wraps your Bash or R scripts into reusable modules. To write effective modules, you must understand Nextflow directives and data types.

**1. Directives and Task Variables**

Directives control the environment and behavior of your specific process.

**A. Global Implicit Variables**
|Variable|Function|Example|
|---------|--------|-------|
|```publishDir```|Saves specific output files to your final results folder. (Otherwise, files remain hidden in temporary directories).|```publishDir "${params.outdir}/fastqc", mode: 'copy'```|
|```launchDir```|This points to the directory where the user actually typed ```nextflow run ...``` in their terminal.| ```[user@server: ~/my/folder] nextflow run main.nf```|
|```workDir```| Points to the path of the temporary scratch directory (usually ```work/```)| e.g. ```$projectDir/work/3f/55560c68752026892c4267c4a42105/```|
|```params```| The global parameter dictionary. Any variable prefixed with ```params.``` can be dynamically overridden by the user from the command line using ```--reads```| e.g ```params.reads```|

**B. Essential Directives**
|Directive|Function|Example|
|---------|--------|-------|
|```task.cpus``` and ```task.memory```|These are dynamic global variables. Instead of hardcoding threads 4 in your Bash script, use ${task.cpus}.| e.g. ```fastqc -t ${task.cpus} reads.fastq.gz```|
|```tag```|Customizes terminal logs to show exactly which sample is currently processing.| ```[3f/55560c] FASTQC (FastQC on SRR1039520)```|
|```container```|Specifies the exact image to pull for this step if not globally defined.|```container 'biocontainers/fastqc:v0.11.9_cv8'```|
|```errorStrategy```|Defines pipeline behavior upon task failure (```terminate```, ```ignore```, ```retry```).|```errorStrategy 'retry'```|

<img width="545" height="212" alt="image" src="https://github.com/user-attachments/assets/ebdadd10-a0df-42e0-a157-f3619badf04e" />

-----------------------

**2. Input and Output Types**
Nextflow needs to know exactly what kind of data is flowing into and out of your process so it can stage the files correctly in the temporary work directories.
|Type|Description|Examples Use Case|
|----|-----------|-----------------|
|```val```|A simple value or string. It is not a file.|Passing a sample ID: ```val(sample_id)```|
|```path```|A physical file or directory path. Nextflow will symlink this into the task's execution folder.|Passing a FASTQ file: ```path(fastq_file)```|
|```tuple```|A logical grouping of multiple elements that must travel together through an input channel. |Pairing an ID with its files: ```tuple val(sample_id), path(reads)```|
```env```|Captures an environment variable set in the script block.|```env(MY_VAR)```|
```stdout```|Captures standard output printed to the terminal.| *stdout*|

----------------------

### Part 3: Group Assignment
> *Your task is to convert hollow ```.nf``` templates into functional **processes** using your optimized container commands.*

**The Assignments**
- Group 1: Quality Control | Complete ```fastqc.nf```
- Group 2: Read Trimming | Complete ```trimming.nf```
- Group 3: Quantification | Complete ```salmon.nf``` (*only quantification*)
- Group 4: Differential Expression | Complete ```r_analysis.nf``` (using the R limma package)

> All of these processes rely on the containers built and pushed to [DockerHub](https://hub.docker.com/repository/docker/hcemm/bioinfo-workshop) in the previous part.

**Submission Protocol**
Once the processes are updated, please:
- Commit to your group branch: ```git commit -m "some message + group name"```
- Push to [```HCEMM/rnaseq-nextflow```](https://github.com/HCEMM/rnaseq-nextflow) repository
- Check Github Actions (CICD) syntax and Nextflow tests (```nf-test```)
- When all checks are passed, open a Pull Request (PR) to ```developer``` branch!

<img width="758" height="373" alt="image" src="https://github.com/user-attachments/assets/aa44574f-4916-4713-8bea-60a974def165" />

<br/>

> Once all groups have created a PR, a whole pipeline test will be performed! ✅

---------
### Group and branch names
|Group|Tool|Branch|DockerHub Tag|
|------|--------|-------|----------|
| Group1 | FastQC + MultiQC |fastqc-g1| hcemm/bioinfo-workshop:fastqc|
| Group2| trimmomatic |trimming-g2| hcemm/bioinfo-workshop:trimming|
| Group3 | salmon |salmon-g3| hcemm/bioinfo-workshop:salmon|
| Group4 | R + limma |limma-g4| hcemm/bioinfo-workshop:limma|

### Questions:
> 1. How do you specify the correct DockerHub container image for your group's tool within the Nextflow process?
> 2. According to the submission protocol, what automated checks must pass before you are allowed to open a Pull Request?
> 3. When opening your Pull Request, which branch must be the target (base), and which is your source (compare) branch?

### Part 4: Execution & Debugging
Once all PRs are merged into the main branch and tested with Github Actions, we can execute our pipeline.

```
nextflow run main.nf -resume
```
> *Note on ```-resume```: If the pipeline crashes, fix the typo and run this exact command again. Nextflow uses cached hashes to skip completed steps and instantly restart at the point of failure.*

<img width="1335" height="244" alt="image" src="https://github.com/user-attachments/assets/473e7a9b-8c05-4d38-bbbf-ebf3c8e11f68" />

-------------------

### Inspecting the Outputs
Nextflow generates two critical directories. Knowing the difference is key to debugging. (```work``` and ```results```)

1. The ```work/``` Directory (The Engine Room)
- Every task runs in an isolated, hashed subdirectory (e.g. ```work/7b/3a1c9f....```)
- Debugging: If a job fails, navigate to its specific hash directory and read the ```.command.err``` and ```.command.sh``` files to see exactly what broke.



2. The ```results/``` Directory (The Display Case)
Driven by the ```publishDir``` directive, this is where your clean, final data lives (e.g., _MultiQC_ HTML reports, _Salmon_ count matrices, _Limma_ Volcano plots).

### Questions: 
> 1. If Nextflow crashes and prints `Error executing process > 'TRIMMOMATIC (Sample_1)' [7b/3a1c9f]`, what is the exact file path you need to investigate, and which specific hidden file contains the error message?
> 2. _Scenario_: You successfully run the entire pipeline without any errors, but when you look inside your `results/` folder, it is completely empty. What Nextflow directive is likely missing from your process scripts?
> 3. The `work/` directory can quickly grow to hundreds of gigabytes because it stores every intermediate file. If you delete the `work/` directory to save space, what Nextflow superpower do you instantly lose for your next run?
> 4.  _Scenario_: You can see the Salmon count matrices in `results/`, but you cannot find the intermediate `.bam` or `.fastq` files here. Why are they missing, and where are they actually stored?

---------------

### Pipeline info and output plots

**Nextflow report and timeline view**

> *Using ```-with-report``` and ```-with-timeline``` options*


<img width="700" alt="image" src="https://github.com/user-attachments/assets/e1f3112d-0bbf-4e0b-ae0c-b5d59013dfef" />
<img width="700" alt="image" src="https://github.com/user-attachments/assets/9723f014-5e82-401c-af17-7eebc3451c4b" />

---------------

**Differential expression plots**

> Airway smooth muscle cells (hASMs) treated with Dexamethasone

<div class="grid" markdown>

<img height="400" alt="image" src="https://github.com/user-attachments/assets/1a9d1205-a4e3-470b-9c97-fb255b680026" />

<img height="400" alt="image" src="https://github.com/user-attachments/assets/be4ff97d-0543-40bd-9b44-6d6e67e59661" />

<img height="400" alt="image" src="https://github.com/user-attachments/assets/f7569e0d-4198-4065-9c2c-ef0e68714cfa" />

<img height="400" alt="image" src="https://github.com/user-attachments/assets/c9f36768-83ff-4ecc-afff-bf2d464d01f4" />


</div>

### Questions:
> 1. Look at your generated Volcano plot and compare it to the results usually seen in published RNA-seq papers. Did we lose a lot of biological information about the dexamethasone treatment by using mock data? 
> 2. How exactly does a massive reduction in sequencing depth (total read count) affect our statistical power? (Hint: Think about how low read counts impact the adjusted p-values on the Y-axis versus the log-fold change on the X-axis).
> 3. If you look closely, a few genes might still appear highly significant despite the mock data. Biologically speaking, what kind of genes are robust enough to survive such aggressive downsampling?

----------------

**Congratulations! You have successfully built, containerized, and automated a collaborative bioinformatics workflow!**

------------------
|Previous|Home|Next|
|--------|----|----|
|[Workflow Managers](../03_Workflow_Managers/README.md)|[Home](../README.md)|[Conda](../05_nf-test/README.md)
