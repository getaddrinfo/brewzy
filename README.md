# brewzy

A project designed to speed up brew.

## Why?

We've all been there - trying to use brew and it just... takes... ages...

## How?

Rewritten and partially redesigned - with full backwards compat (as best I can), to make changing over a breeze.

## Explanation

`brewzy` consists of two different parts: The `api` and the `cli`.

The `api` handles keeping track of commonly used casks, allows the CLI to quickly check if their casks are outdated (without `git pull origin ...` for all casks/formulae, as we 
keep track of commonly used casks/formulae too). If you wish to add a cask to the checked casks, open an Issue.

The `cli` is used by you, similarly to the `brew` you are probably familiar with. The plan is that you (ideally) won't need to change anything, but we will see how that
pans out.

### API

- [x] Complete `formulae.brew.sh` sync job.
- [ ] Complete `git` sync job.
- [ ] Complete `ets` cache implementation.
- [ ] Complete `/formulae` routes.
- [ ] Complete `/casks` routes.
- [ ] Complete `/diff` route. 


### CLI

The CLI plans to implement "user" commands first, then "developer" commands.

- [ ] Ruby runtime.
- [ ] Arg parsing.
- [ ] Sources (where to load casks/formula/taps) - you opt in to using our `api`.
- [ ] Auto-completion.
- [ ] User commands.
- [ ] Developer commands.

## Future Plans

In future, I may eventually offer a service that allows us to keep track of *any* cask that you use, not just the casks that are commonly used. Ideally, this means
that you *don't* have to wait for `brew update` to sync all the repositories on your system, instead using our API to diff the current casks that you have.

This comes with the added necessity of identifying users (i.e., offering a way of signing up to our service, and keeping a history of what taps/casks/formulae
you use). 

## Licence
MIT