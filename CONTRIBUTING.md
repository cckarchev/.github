# Contributing

Thanks for helping with the Centro Cultural Karchev projects. These are
community tools for the club and its players, built in spare time, so small,
focused contributions are the easiest to review.

## Reporting a problem

Open an issue with the matching template:

- **Bug report** for something that does not work as it should.
- **Data error** for a wrong card, unit, stat or rule in a builder or
  calculator. Say where the correct value comes from (rulebook, card, errata),
  so it can be checked.
- **Feature request** for something you would like the tool to do.

Search the open issues first; a thumbs up on an existing one helps more than a
duplicate.

## Making a change

1. Fork the repository and create a branch named after the change, such as
   `fix/unit-points` or `feat/print-layout`.
2. Install with `npm ci`. Every project needs the Node version in its
   `.node-version` file.
3. Make the change. Keep it to one topic per pull request.
4. Run `npm run verify` before pushing. It runs the same checks as CI: Biome,
   the type checker, the tests and the build. `npm run check:fix` fixes most
   formatting and lint findings on its own.
5. Open a pull request and fill in the template.

## Conventions

- Code, comments, documentation and every string the app shows are in English.
- Formatting and lint rules come from the shared Biome preset in
  [cck-shared](https://github.com/cckarchev/cck-shared); do not add ESLint or
  Prettier.
- Design tokens (colors, spacing, type) come from cck-shared too. Use them
  through `var(--token)` instead of literal values.
- Pull requests are squash merged, and the pull request title becomes the
  commit message, so write it in
  [Conventional Commits](https://www.conventionalcommits.org/) style:
  `fix: correct points cost for war machines`.

## Game material

The games these tools support belong to their publishers. Do not add scanned
pages, card art or rules text beyond what a tool needs to work.
