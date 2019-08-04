# Folderfy

Folderfy is a bash script that allows for storage of templated folder structures so users can deploy them easily and rapidly through the terminal.
You'll be able to save template folder structures including their files (like files with startup frameworks) and easily construct them at any location.
No more hassle copying standard structures from one location to another, or re-constructing the same file structure over and over again.

## Installation

To install make sure you a bin directory in your user directory.

```console
mkdir $HOME/.bin
```

if you do not yet have a .bashrc and/or .bash_profile file

```console
touch .bashrc
touch .bash_profile
```

Add the following path to .bashrc (and/or) .bash_profile. This is to include your new .bin directory as a source for bash executables.

```bash
export PATH="$HOME/.bin:$PATH"
```

Now copy the script to the .bin directory in your home folder and change permissions to executable.

```console
chmod u+x $HOME/.bin/folderfy
```

NOTE: Folderfy will construct a .folderfy_templates folder in the user/.bin directory upon running for the first time.
This directory is used to save compressed (.zip) folder structures for future deployment use.

## Usage

By initiating folderfy with full words it will guide the user through the process.

```console
folderfy make [Will construct a directory at the given location]
folderfy add [Add a pre-made template to Folderfy]
folderfy update [Update an existing template]
folderfy rename [Rename an existing template]
folderfy list [Print all available templates to the console]
```

When initiating folderfy with flags, it won't guide the user through the process.
This will be faster to operate but requires a more experienced user.

```console
folderfy -m <Name of template to construct> -p <Path to desired location>
folderfy -a <Name to save template to> -p <Path to pre-made template folder structure>
folderfy -u <Name of template to update> -p <Path to folder structure to use as updated version>
folderfy -r <Name of template to rename> -n <New name for template>
folderfy -l
```