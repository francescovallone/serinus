# Create

The `create` command is used to create a new Serinus project.

## Usage

To create a new Serinus project, run the following command:

```bash
serinus create <project-name>
```

This command will create a new directory with the name `<project-name>` and will generate the necessary files to start a new Serinus project.

If you want to use a different name for the project, you can use the `--project-name` flag:

```bash
serinus create . --project-name <project-name>
```

This command will try to create in the current directory the necessary files to start a new Serinus project with the name `<project-name>`.

## Force creation

If you want to force the creation of the project even if the directory is not empty, you can use the `--force` flag:

```bash
serinus create . --force
```

This command will create the project even if the directory is not empty.
