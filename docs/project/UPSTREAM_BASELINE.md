# OWASP NodeGoat Upstream Baseline

## Source Project

OWASP NodeGoat

## Official Repository

https://github.com/OWASP/NodeGoat

## Purpose

NodeGoat is used as the intentionally vulnerable open-source
application for the IE3142 DevOps Security assignment.

## Import Strategy

The official repository is cloned temporarily and exported into:

```text
app/
```

The upstream `.git` directory is intentionally not copied.

This ensures that the entire university project uses one Git
repository while still preserving the exact original NodeGoat source.

## Upstream Commit

```text
c5cb68a7084e4ae7dcc60e6a98768720a81841e8
```

## Upstream Branch

```text
master
```

## Upstream Commit Date

```text
2023-06-21T10:23:23+03:00
```

## Upstream Commit Message

```text
Merge pull request #290 from za/add-blank-space
```

## License

Apache License 2.0

## Original Components

Primary components:

1. Node.js / Express web application
2. MongoDB database

## Original Docker Support

The upstream repository contains:

- Dockerfile
- docker-compose.yml

These files are initially preserved without modification.

## Baseline Rule

The imported NodeGoat application source must remain untouched until
the vulnerable baseline has been documented and tagged.

All future security modifications will be performed through dedicated
branches.

## Baseline Tag

The project will use:

```text
vulnerable-baseline
```

to identify the untouched NodeGoat baseline.

## Ethical Boundary

Security testing is limited to the authorised local project instance.

No third-party system will be tested.
