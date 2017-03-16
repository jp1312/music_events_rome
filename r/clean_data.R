
library(jsonlite)
library(rgdal)
library(lubridate)
library(dplyr)



## --- import data retrieved from AllEvents API (via Python)
concertsPg0 <- fromJSON("C:/Users/pc/Documents/slowdata/post/eventi_roma/git/python/rm_concerts_2003_2703_pg0.json")
partiesPg0 <- fromJSON("C:/Users/pc/Documents/slowdata/post/eventi_roma/git/python/rm_parties_2003_2703_pg0.json")
musicPg0 <- fromJSON("C:/Users/pc/Documents/slowdata/post/eventi_roma/git/python/rm_music_2003_2703_pg0.json")
musicPg1 <- fromJSON("C:/Users/pc/Documents/slowdata/post/eventi_roma/git/python/rm_music_2003_2703_pg1.json")
musicPg2 <- fromJSON("C:/Users/pc/Documents/slowdata/post/eventi_roma/git/python/rm_music_2003_2703_pg2.json")

## --- extract only data of interest
concert <- concertsPg0$data[,c('event_id', 'eventname', 'start_time', 'start_time_display', 'end_time', 'end_time_display', 'location')]
concert$lat <- concertsPg0$data$venue$latitude
concert$lon <- concertsPg0$data$venue$longitude
concert$cat <- "concert"

party <- partiesPg0$data[,c('event_id', 'eventname', 'start_time', 'start_time_display', 'end_time', 'end_time_display', 'location')]
party$lat <- partiesPg0$data$venue$latitude
party$lon <- partiesPg0$data$venue$longitude
party$cat <- "party"

music0 <- musicPg0$data[,c('event_id', 'eventname', 'start_time', 'start_time_display', 'end_time', 'end_time_display', 'location')]
music0$lat <- musicPg0$data$venue$latitude
music0$lon <- musicPg0$data$venue$longitude

music1 <- musicPg1$data[,c('event_id', 'eventname', 'start_time', 'start_time_display', 'end_time', 'end_time_display', 'location')]
music1$lat <- musicPg1$data$venue$latitude
music1$lon <- musicPg1$data$venue$longitude

music2 <- musicPg2$data[,c('event_id', 'eventname', 'start_time', 'start_time_display', 'end_time', 'end_time_display', 'location')]
music2$lat <- musicPg2$data$venue$latitude
music2$lon <- musicPg2$data$venue$longitude
music <- rbind(music0, music1, music2)
music$cat <- "music"

data <- rbind(concert, party, music)
str(data)


## --- consistency checks
data$start_date <- substr(x = data$start_time_display, start = 5, stop = 10)
data$end_date <- substr(x = data$end_time_display, start = 5, stop = 10)
table(data[,c('start_date', 'end_date')]) # ok

## --- remove duplicates (some events belong to multiple categories)
nrow(data)
data <- data[!duplicated(data$event_id),]
nrow(data)


## --- clean start and end dates
table(sapply(data$start_time_display, nchar)) # all dates have 27 characters
table(sapply(data$end_time_display, nchar)) # all dates have 27 characters

start_date1 <- substr(x = data$start_time_display, start = 5, stop = 27)
start_date2 <- as.POSIXct(start_date1, format = '%b %d %Y at %I:%M %p')
end_date1 <- substr(x = data$end_time_display, start = 5, stop = 27)
end_date2 <- as.POSIXct(end_date1, format = '%b %d %Y at %I:%M %p')


## --- calculate new fields

# event duration
difftime(end_date2, start_date2, units = "hours")

# 0 hours??
start_date2[1]
end_date2[1]
data$start_time_display[1]
data$end_time_display[1]
data$eventname[1] # mm.. they are events where the organizer did not set the end_date (https://allevents.in/rome/club-mario-pride-pub-roma/1008517492615876)

# 319 hours??
start_date2[64]
end_date2[64]
data$start_time_display[64]
data$end_time_display[64]
data$eventname[64] # mmm, they are events stretching along multiple days... (https://allevents.in/rome/blume-domenica-12-marzo-aperitivochecanta-2/643785949157977)

# start hour
t.lub <- ymd_hms(start_date2)
head(t.lub)

# extract time as decimal hours
h.lub <- hour(t.lub) # + minute(t.lub)/60
head(h.lub)

# end hour
t.lub2 <- ymd_hms(end_date2)
head(t.lub2)
# extract time as decimal hours
h.lub2 <- hour(t.lub2) # + minute(t.lub)/60
head(h.lub2)
sum(start_date2 == end_date2) # most cases end_date == start_date. this should mean end date was not set
idx <- start_date2 == end_date2
head(data$eventname[idx])
h.lub3 <- rep(NA, length(h.lub2))
h.lub3[!idx] <- h.lub2[!idx]
end_date3 <- rep(NA, length(end_date2))
end_date3[!idx] <- end_date2[!idx]

data$start_date_formatted <- start_date2
data$end_date_formatted <- end_date3
data$start_hour <- h.lub
data$end_hour <- h.lub3

# extract weekday
data$wday <- wday(data$start_date_formatted, label = TRUE)


## --- remove events starting before 20 March and after Sunday 26 March to have a clean full week
str(data)
head(data$start_date_formatted)
idx_outweek <- with(data, start_date_formatted<"2017-03-20 01:00:00 CET" | start_date_formatted>"2017-03-27 01:00:00 CET")
nrow(data)
data <- data[!idx_outweek,]
nrow(data)


## --- remove invalid coordinates
crslonglat = CRS("+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs +towgs84=0,0,0")
events <- SpatialPoints(data[, c("lon", "lat")], proj4string = crslonglat)
summary(events)
bbox(events)
sum(data$lat < 41 | data$lat > 43)
sum(data$lon < 11 | data$lon > 13)
idx <- data$lon < 11 | data$lon > 13
idx
data <- data[!idx,]
nrow(data)

## --- quick visualization/explorations
hist(h.lub, nclass = 30)
table(data$day)
data$label_week <- paste0(substr(data$day, 1, 3), "-", data$start_hour, "h")
data %>%
  group_by(wday) %>%
  summarise(N = length(event_id)) 
plot.data1 <- table(data$wday)/sum(table(data$wday))

# export csv
# write.csv(x = data, file = "C:/Users/pc/Documents/roma_live_music_contest/r/data_AE.csv")

tmp.env <- new.env()
assign("week_events_rome", data, pos=tmp.env)
save(list=ls(all.names=TRUE, pos=tmp.env), envir=tmp.env, file="C:/Users/pc/Documents/slowdata/post/eventi_roma/git/data/cleaned_data.RData")
rm(tmp.env)

