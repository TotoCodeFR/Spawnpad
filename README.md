# Spawnpad

A Roblox game that acts as a launcher, alongside features such as music, party, and much more.

## Requirements

This project uses [rokit](https://github.com/rojo-rbx/rokit) to manage the Roblox development tools, [pnpm](https://pnpm.io/) to manage Node.js dependencies and scripts and [corepack](https://nodejs.org/api/corepack.html) to manage the pnpm installation.
You will need to have rokit and Node.js installed and added to your PATH (`corepack` isn't required but recommended).

## Installation

```bash
# Clone the repository
git clone https://github.com/TotoCodeFR/Spawnpad.git

# Install dependencies
cd Spawnpad
corepack enable
pnpm install
rokit install

# Copy the .env.example file to .env
cp .env.example .env

# Edit the .env file to set your environment variables

# Push the database schema
pnpm db:push

# To serve the game through Rojo
rojo serve

# To build the game
rojo build --output spawnpad.rbxlx

# To generate a Rojo sourcemap file
rojo sourcemap default.project.json -o sourcemap.json

# To format
pnpm format

# To simply check
pnpm format:check
```

## License

This project is licensed under the MIT License. See the [LICENSE](./LICENSE) file for details.
