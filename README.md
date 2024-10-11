# Dataphos Docs

This repository contains the official documentation and examples of the Dataphos platform components. The following link will lead you to the official web page where the documentation is hosted: [docs.dataphos.com](https://docs.dataphos.com/).

## Usage 
### How to Run the Site Locally

1. Install [Hugo](https://gohugo.io/).
2. In the `dataphos-docs/themes/hugo-geekdoc` folder, run `npm install` and `npm run build`.
3. Navigate to the `dataphos-docs` folder and run `hugo server -D`. This should result in the server running on `localhost:1313`.

### How to Edit the Content

The content is managed as a set of Markdown files in the `dataphos-docs/content` folder. Every markdown file is its own static page. See the `persistor/quickstart.md` as an example of how to utilize some basic editing.

The order the pages will be displayed in the sidebar is determined by the `weight` parameter of the Markdown file header.

### How to Edit the Look

You can configure the look and feel of the site by editing the `static/custom.css` file.

## Examples

Any examples or files used as part of the deployment instructions are made available in the `examples` folder of this repository.
