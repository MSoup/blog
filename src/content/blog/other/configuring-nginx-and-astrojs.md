---
title: "5 Steps to Get Your AstroJS Site Hosted With Nginx"
description: "In fact, these are the steps I took to host this site"
pubDate: "Aug 6 2023"
heroImage: "/placeholder-hero.jpg"
---

# Prerequisites

I will assume you already have an AstroJS project ready for deployment. You've configured pages as needed and you just need to throw the static bundle on a host. You've installed your required dependencies such as node and `npm install`.

# Step 1: Build your AstroJS project

Example script run

```bash
npm run build

> build
> astro build

The site configuration value includes a pathname of /blog/ but there is no base configuration.

A future version of Astro will stop using the site pathname when producing <link> and <script> tags. Set your site's base with the base configuration.
09:41:19 AM [content] Types generated 270ms
09:41:19 AM [build] output target: static
09:41:19 AM [build] Collecting build info...
09:41:19 AM [build] Completed in 464ms.
09:41:19 AM [build] Building static entrypoints...
09:41:20 AM [build] Completed in 1.51s.

 generating static routes
▶ src/pages/index.astro
  └─ /index.html (+8ms)
λ src/pages/rss.xml.js
  └─ /rss.xml (+16ms)
▶ src/pages/about.astro
  └─ /about/index.html (+8ms)
▶ src/pages/blog/index.astro
  └─ /blog/index.html (+6ms)
▶ src/pages/blog/[...slug].astro
  ├─ /blog/other/markdown-style-guide/index.html (+15ms)
  ├─ /blog/other/using-mdx/index.html (+22ms)
  ├─ /blog/other/third-post/index.html (+29ms)
  ├─ /blog/ci-cd/local-jenkins-github-apple-silicon/index.html (+35ms)
  ├─ /blog/aws/deploy-lambdas-rapidly/index.html (+42ms)
  └─ /blog/other/second-post/index.html (+48ms)

 generating optimized images
  ▶ /_astro/cert-viewer.123d4748_1DhooM.webp (reused cache entry) (+1ms)
Completed in 147ms.

@astrojs/sitemap: `sitemap-index.xml` is created.

09:41:20 AM [build] 9 page(s) built in 2.16s
09:41:20 AM [build] Complete!
```

This produces a `dist` folder with all of your static contents in there. We will need it soon to deploy on your host.

# Step 2: Install nginx on the Host

Depending on where your host is, the configuration and installation steps may be different. Go [here](https://nginx.org/en/linux_packages.html#Ubuntu) for the various ways to install it on different systems.

## Installation

I am using an Ubuntu host, and these are the steps for it:

```bash
sudo apt install curl gnupg2 ca-certificates lsb-release ubuntu-keyring

curl https://nginx.org/keys/nginx_signing.key | gpg --dearmor \
    | sudo tee /usr/share/keyrings/nginx-archive-keyring.gpg >/dev/null

echo "deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] \
http://nginx.org/packages/ubuntu `lsb_release -cs` nginx" \
    | sudo tee /etc/apt/sources.list.d/nginx.list

echo -e "Package: *\nPin: origin nginx.org\nPin: release o=nginx\nPin-Priority: 900\n" \
    | sudo tee /etc/apt/preferences.d/99nginx

sudo apt update
sudo apt install nginx

```

If you are installing on Amazon Linux, nginx is available in the amazon-linux-extras repository. The command would be `sudo amazon-linux-extras install nginx1`

## Running

Run `sudo systemctl status nginx`

If it shows that nginx is not yet running, enable it by running `sudo systemctl start nginx`

\*You can also invoke nginx through `/etc/init.d/nginx`, such as `sudo /etc/init.d/nginx start`

## Note

After configuration changes, it is a good practice to restart nginx. You do not need to force stop and start. You can simply run `sudo /etc/init.d/nginx reload`. This is known as a graceful restart. Use graceful restarts, as it gives nginx time to shut down child processes as opposed to killing them. Operations should not be disturbed through this method.

# Step 3: Move dist into your host machine

Make a directory located at `/data/www/dist/` (it can be anywhere really), and dump the contents in! You may need to configure your host machine to be able to be SSH'd into, otherwise the below `scp` command will fail. If you get a publickey denied error, please add your public key to your host's `authorized_keys` file, located at `./ssh/authorized_keys`.

From your root directory of your AstroJS project (the same directory where `dist` lives)

```
scp -r ./dist/* USERNAME@YOUR_HOST_IP:/data/www/dist
```

# Step 4: Configure Nginx

Assuming I have my static site content served behind `/data/www/dist/`, my nginx config, located at `/etc/nginx/nginx.conf` looks something like this

```
user  nginx;
worker_processes  auto;

error_log  /var/log/nginx/error.log notice;
pid        /var/run/nginx.pid;


events {
    worker_connections  1024;
}


http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;

    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';

    access_log  /var/log/nginx/access.log  main;

    sendfile        on;
    #tcp_nopush     on;

    keepalive_timeout  65;

    #gzip  on;

    include /etc/nginx/conf.d/*.conf;
    include /etc/nginx/sites-enabled/*.conf;
}
```

In the last line, you can see that this configuration file points to `include /etc/nginx/sites-enabled/*.conf`, so everything in the directory `sites-enabled/` that ends in .conf is matched. Let's make a conf file there!

`/etc/nginx/sites-enabled/cloudsoup.net.conf`

```
server {
    listen 80;
    server_name example.com;

    charset utf-8;
    root /data/www/dist;
    index index.html index.htm;

    location / {
        try_files $uri $uri/ =404;
    }

    location /about {
        try_files $uri $uri/ /about/index.html;
    }

    location /blog {
        try_files $uri $uri/ /blog/index.html;
    }
}
```

## Note

- `listen`: port 80 is the default for serving web traffic over HTTP
- `server_name`: your server name goes here, nginx will know to respond to requests coming into `server_name` with this whole block
- `charset utf-8`: This sets the character encoding to UTF-8
- `root` refers to where your static files are, this becomes the base directory to which all location blocks below reference from; more on this below
- `index` tells nginx what to look for when a directory is accessed.
  When running `astro build`, it produces a `dist` directory. Throw the whole directory here for convenience, such that in `/data/www/dist` it might look like:

- \_astro/
- blog/
- about/
- index.html
- placeholder-hero.jpg
- placeholder-about.jpg
- placeholder-social.jpg
- rss.xml
- sitemap-0.xml
- sitemap-index.xml
- favicon.svg

`location /about` and `location /blog` directives are optional. They are already matched by `/`, but it seems that nginx seems to optimize a little further when it knows those paths exactly. This probably doesn't lead to noticeably different response times, but I figured it doesn't hurt.

Now that your `/etc/nginx/sites-enabled/[EXAMPLE].conf` file is loaded up, reload nginx

```
sudo /etc/init.d/nginx reload
```

# Step 5: Test Your Website

Finally, test that your website is accessible by visiting your IP in a web browser or running a curl command against it:

```
curl http://143.198.144.49/
```

If there is a response, congratulations! If not, hopefully you have a good base to start digging for answers from.
