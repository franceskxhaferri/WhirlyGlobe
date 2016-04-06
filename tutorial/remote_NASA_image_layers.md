---
title: NASA Image Layers
layout: tutorial
---

*Tutorial developed by Chris Lamb.*

**This tutorial requires WhirlyGlobe-Maply version 2.4 or greater.**

NASA provides a wealth of earth imagery and remote sensing data.  Most of it needs to be reprocessed in some way for visual display, but some can be used directly.  The [Global Imagery Browse Services](https://earthdata.nasa.gov/about/science-system-description/eosdis-components/global-imagery-browse-services-gibs) or GIBS site provides a variety of imagery layers we can use directly in WhirlyGlobe-Maply.

You'll need to have done the [Remote Image Layer](remote_image_layer.html) tutorial.  Open your HelloEarth project and get ready.

![Xcode ViewController.m]({{ site.baseurl }}/images/tutorial/NASA_GIBS_Header.png)

If you haven't got one here is a suitable [ViewController.m]({{ site.baseurl }}/tutorial/code/ViewController_vector_selection.m) file to start with.  This version has a remote image layer already configured and it makes a nice starting point.

In this tutorial we are going to get a base layer map from the GIBS site, and then we will add an overlay layer to that globe.

### NASA GIBS base layer tile sources  

The NASA GIBS site has a dizzying array of data sources to choose from.  If you poke around their WMS XML you can find all sorts of things.  We'll pick one of the layers to dispaly, the corrected reflectance product.

All we need to do is replace the existing MaplyRemoteTileSource URL with one supplied thru the [GIBS website](https://wiki.earthdata.nasa.gov/display/GIBS/GIBS+Available+Imagery+Products#expand-CorrectedReflectance5Products).  Here are two URLs that provide a base layer for your Whirly Globe.

{% highlight bash %}
http://map1.vis.earthdata.nasa.gov/wmts-webmerc/MODIS_Terra_CorrectedReflectance_TrueColor/default/2015-06-07/GoogleMapsCompatible_Level9/{z}/{y}/{x}
{% endhighlight %}

{% highlight bash %}
http://map1.vis.earthdata.nasa.gov/wmts-webmerc/VIIRS_CityLights_2012/default/2015-07-01/GoogleMapsCompatible_Level8/{z}/{y}/{x}
{% endhighlight %}
Now let's decipher these URLs.  A reading of the [GIBS API reference](https://wiki.earthdata.nasa.gov/display/GIBS/GIBS+API+for+Developers) shows that the string has the format;

{% highlight bash %}
http://map1.vis.earthdata.nasa.gov/{Projection}/{ProductName}/default/{Time}/{TileMatrixSet}/{ZoomLevel}/{TileRow}/{TileCol}.png
{% endhighlight %}

Open ViewController.m. Now let's find where to add the image layer URL.  Scroll down thru viewDidLoad until you find the following code for a MaplyRemoteTileSource;

{% highlight objc %}
// MapQuest Open Aerial Tiles, Courtesy Of Mapquest
// Portions Courtesy NASA/JPL­Caltech and U.S. Depart. of Agriculture, Farm Service Agency
MaplyRemoteTileSource *tileSource =
[[MaplyRemoteTileSource alloc]
    initWithBaseURL:@"http://otile1.mqcdn.com/tiles/1.0.0/sat/"
    ext:@"png" minZoom:0 maxZoom:maxZoom];
{% endhighlight %}

- Replace the initWithBaseURL property with one of the selections above.
- Also change ext: to "jpg"
- And match the maxZoom with the level of the GoogleMapCompatible Level (8 or 9)

Run the project, and you should get something like this.

![NASA NightSky base map]({{ site.baseurl }}/images/tutorial/NASA_NightTime_Layer.png)

That gives us a nice night basemap, but many of the GIBS layers are overlays and work best on top of other data.

### Adding an Overlay Layer

For our next feat let's add an overlay image to our globe.  Below are a couple of GIBS URLs for overlay suitable data sets.

{% highlight bash %}
http://map1.vis.earthdata.nasa.gov/wmts-webmerc/Sea_Surface_Temp_Blended/default/2013-06-07/GoogleMapsCompatible_Level7/
{% endhighlight %}

{% highlight bash %}
http://map1.vis.earthdata.nasa.gov/wmts-webmerc/MODIS_Terra_Land_Surface_Temp_Day/default/2013-06-07/GoogleMapsCompatible_Level7/
{% endhighlight %}

{% highlight bash %}
http://map1.vis.earthdata.nasa.gov/wmts-webmerc/MODIS_Terra_Chlorophyll_A/default/2015-02-10/GoogleMapsCompatible_Level7/
{% endhighlight %}

Add this above viewDidLoad

{% highlight objc %}
// Set this for different view options
const bool DoOverlay = true;
{% endhighlight %}

Now just add this code to the bottom of ViewDidLoad, above the addCountries call.

{% highlight objc %}
// Setup a remote overlay from NASA GIBS
if (DoOverlay)
{
  // For network paging layers, where we'll store temp files
  NSString *cacheDir = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)  objectAtIndex:0];

  MaplyRemoteTileSource *tileSource = [[MaplyRemoteTileSource alloc] initWithBaseURL:@"http://map1.vis.earthdata.nasa.gov/wmts-webmerc/Sea_Surface_Temp_Blended/default/2015-06-25/GoogleMapsCompatible_Level7/{z}/{y}/{x}" ext:@"png" minZoom:0 maxZoom:9];
  tileSource.cacheDir = [NSString stringWithFormat:@"%@/sea_temperature/",cacheDir];

  tileSource.tileInfo.cachedFileLifetime = 60*60*24; // invalidate OWM data after 24 hours
  MaplyQuadImageTilesLayer *temperatureLayer = [[MaplyQuadImageTilesLayer alloc] initWithCoordSystem:tileSource.coordSys tileSource:tileSource];

  temperatureLayer.coverPoles = false;
  temperatureLayer.handleEdges = false;
  [globeViewC addLayer:temperatureLayer];
}
{% endhighlight %}

Next, you can change the MaplyRemoteTileSource to any of the URLs provided above.

{% highlight objc %}
MaplyRemoteTileSource *tileSource = [[MaplyRemoteTileSource alloc] initWithBaseURL:@"http://map1.vis.earthdata.nasa.gov/wmts-webmerc/Sea_Surface_Temp_Blended/default/2013-06-07/GoogleMapsCompatible_Level7/"
ext:@"png" minZoom:1 maxZoom:7];
{% endhighlight %}

If you do change the URL, be sure to change the name of the cache directory.  Otherwise you'll get a combination of new and old data.
 
Change the initWithBaseURL to any of the URLs listed above.
And don't forget to match the maxZoom level.


That's it! Build and run.  You should see some sweet NASA data! 

![NASA Overlay Ocean Temp Layer]({{ site.baseurl }}/images/tutorial/NASA_SeaTemp_Overlay.png)

That's all there is to it.  Here's a working [ViewController.m]({{ site.baseurl }}/tutorial/code/ViewController_NASA_GIBS.m) if you need it.