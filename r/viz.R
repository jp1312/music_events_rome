#===========================================
# @Project: Eventi Roma
# @Name: main
# @url: http://slow-data.com/eventi_roma
# @author: jprimav
# @date: 2017/03
#===========================================

## --- Libraries
library(RColorBrewer)
library(colorspace)
library(rgdal)
library(maptools)
library(PBSmapping)
library(dplyr)
library(rgeos)
library(leaflet)
library(htmlwidgets)
library(dplyr)
library(htmltools)
library(leaflet)
library(leaflet.extras)





# Read SHAPEFILE with borders of 'zone urbanistiche' (neighborhoods)
zu <- readOGR(dsn = "C:/Users/pc/Documents/slowdata/post/eventi_roma/git/shapes", layer = "ZU_COD")

# change CRS for zu shape file to coicide with OSM data
crslonglat = CRS("+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs +towgs84=0,0,0")
zu <- spTransform(zu, CRS=crslonglat)
plot(zu)

# import events data
load("C:/Users/pc/Documents/slowdata/post/eventi_roma/git/data/cleaned_data.RData")
coords <- SpatialPoints(week_events_rome[, c("lon", "lat")], proj4string = crslonglat)
events <- SpatialPointsDataFrame(coords, week_events_rome)
summary(events)

# events overlay boroughs?
plot(zu)
points(events, col = "red") # they're fine
bbox(zu)
bbox(events)

# Spatial join many-to-one events+zu
str(events@data)
events@data$event_id <- as.factor(events@data$event_id)
events_agg <- aggregate(x = events["event_id"], by = zu, FUN = length)
# The above code identifies which ZU polygon (boroughs) each event is located in and groups them accordingly 
# Another possible aggregation of interest could be something like this:
# aggregate(events["<SOME NUMERICAL VARIABLE>"], by = zu, FUN = mean)
str(events_agg@data)
events_agg$event_id
zu$n_events <- events_agg$event_id
head(zu@data)

# replace NAs with 0s 
zu@data[is.na(zu@data$n_events),"n_events"] <- 0

# I want to add Tiber water basin
tevere <- readOGR(dsn = "C:/Users/pc/Documents/slowdata/post/eventi_roma/git/shapes/tevere.geojson",
                  layer = "OGRGeoJSON")
summary(tevere)
tevere <- spTransform(tevere, CRS=crslonglat)
leaflet(data = tevere) %>%
  addTiles() %>%
  addPolylines() # ok, it's Tiber!


## --- leaflet
MAPBOX_ACCESS_TOKEN <- 'YOUR-MAPBOX-TOKEN-HERE'

labels <- sprintf(
  "<strong>%s</strong><br/>%g Events / Week",
  zu$Name, zu$n_events
) %>% lapply(htmltools::HTML)


# Plot
m <- leaflet(zu) %>%
  setView(12.55, 41.9, 12) %>%
  addProviderTiles("MapBox", options = providerTileOptions(
    id = "mapbox.light",
    accessToken = MAPBOX_ACCESS_TOKEN))

m

hist(zu@data$n_events, nclass = 50)
bins <- c(0, 1, 3, 5, 10, 15, 20, Inf)
previewColors(colorFactor("Reds", domain = NULL), LETTERS[1:5])
pal <- colorBin("Reds", domain = zu$n_events, bins = bins)

m2 <-
m %>% 
  addPolygons(
    fillColor = ~pal(n_events),
    weight = 1,
    opacity = 1,
    color = "white",
    #dashArray = "3",
    fillOpacity = 0.7,
    highlight = highlightOptions(
      weight = 5,
      color = "#666",
      dashArray = "",
      fillOpacity = 0.7,
      bringToFront = TRUE),
    label = labels,
    labelOptions = labelOptions(
      style = list("font-weight" = "normal", padding = "3px 8px"),
      textsize = "15px",
      direction = "auto")) %>%
  addPolylines(data = tevere, col = "blue") %>%
  addControl("<P>Source: <a href=https://allevents.in/ target=_blank>allevents</a></P>", 
             position='topright') %>%
  addScaleBar(position = c("bottomleft")) %>%
  addLegend(pal = pal, values = ~n_events, opacity = 0.7, title = "N. events <br/> 
(music, parties, concerts)<br/> 
            20-27 March '17",
            position = "bottomright") %>%
  addFullscreenControl()
  
m2  

# saveWidget(widget = m2, file = "C:/Users/pc/Documents/slowdata/post/eventi_roma/git/web/eventi_roma.html", selfcontained = FALSE)

  