# Blog sample using Jetzig

A pretty minimal web app sample of a blog that shows how to (server-side) render as Web pages the list of blog articles, each blog article, and how to create one.

Mainly done by following [this screencast](https://www.youtube.com/watch?v=CBKhTrMU5LU). Just minor additions to help the navigation were introduced.

<br/>

## Start

### Prerequisites

-   Run `docker-compose up -d` to start the PostgreSQL server container in the background.
-   Run `jetzig database migrate` to populate the database

### Start the app

Run `jetzig server` to start the app.

<br/>

## Usage

Go to http://localhost:8080/blogs and play with it.
