# Splash pages for NoDogSplash.

![](web/splash/res/splash.png)

NoDogSplash displays two pages to the user that are relevant for our tool here - the splash page, that asks for the token of the user, and the status page.

Here we have the pages in the build directory with the only changing asset the css, based on tailwind. The source is in *src* and the relevant configs is *tailwind.config.js*. If you feel like changing these go on and adapt the html and css, then run npm build.

## So how do we use these pages?

NoDogSplash has a config section where the directory the pages are served from is defined

```
option webroot '/path/to/nodogsplash/htdocs'
```

and this is the place the contents of the entire *build* directory should be copied to
