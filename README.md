# azdops-nginx-mkdocs-starter

## Introduction

This is a template repository for a [MkDocs] site to deploy a static website using [azure-easy-auth-njs/nginx][azure-easy-auth-njs] docker image.

[MkDocs]: https://www.mkdocs.org
[azure-easy-auth-njs]: https://github.com/yaegashi/azure-easy-auth-njs

## Build and Publish

[nginxsiteops.sh](nginxsiteops.sh) is a simple wrapper script that provides various tasks to build and publish a MkDocs website.
You can customize the functions in this script to meet your specific requirements.

To run a development MkDocs server (`cmd_site_serve`):

```
./nginxsiteops.sh site-serve
```

To build website files into the `site` directory (`cmd_site_build`):

```
./nginxsiteops.sh site-build
```

To set up [Rclone configuration for Azure Files Storage](https://rclone.org/azurefiles/) (`cmd_rclone_config`),
use one of the following authentication methods:

1. Access with OAuth over REST (requires Azure CLI for authentication)
    ```
    export NGINX_SHARE_URL="https://{ACCOUNT_NAME}.file.core.windows.net/{SHARE_NAME}"
    ./nginxsiteops.sh rclone-config
    az login --allow-no-subscriptions
    ```
2. Access with SAS URL
    ```
    export NGINX_SHARE_SAS_URL="https://{ACCOUNT_NAME}.file.core.windows.net/{SHARE_NAME}?{SAS}"
    ./nginxsiteops.sh rclone-config
    ```

To upload the built site to Azure Files Storage (`cmd_rclone_sync`):

```
./nginxsiteops.sh rclone-sync [<SITE_NAME>]
```

- `SITE_NAME` defines the website's subdomain (`https://{SITE_NAME}.example.com`).
- When `SITE_NAME` is set to `default` (which is the default value), the website is published without a subdomain (`https://example.com`).

## GitHub Actions workflow

The [site-publish.yml](.github/workflows/site-publish.yml) workflow runs on `push`, `pull_request`, and `workflow_dispatch` triggers to:

- Build the MkDocs site
- Set up Rclone configuration if either of the following authentication methods is configured:
  1. OIDC authentication: `vars.NGINX_SHARE_URL`, `vars.AZURE_TENANT_ID`, and `vars.AZURE_CLIENT_ID`
  2. SAS authentication: `secrets.NGINX_SHARE_SAS_URL`
- For `push` or `workflow_dispatch` events:
  - If the branch is the default branch, `SITE_NAME` is set to `default`, otherwise it's set to the branch name
  - This can be overridden using `workflow_dispatch` input
  - The website is published using the configured `SITE_NAME`
- For `pull_request` events with `vars.PREVIEW_URL` set:
  - The website is published with a temporary `SITE_NAME`
  - A comment with the preview URL is added to the PR discussion using the GitHub Actions bot account
    |`vars.PREVIEW_URL`|Resulting preview URL|
    |-|-|
    |`https://example.com/ja/intro`|`https://pr-<NNN>-<COMMIT>.example.com/ja/intro`|
