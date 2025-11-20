#install.packages('terra')
#install.packages('sf')
#install.packages('rnaturalearth')


# Setup -------------------------------------------------------------------

library('terra')
library('rnaturalearth')
library('sf')


# Read in Data ------------------------------------------------------------

streets = vect('data/raw/StreetCenterlines.shp')
plot(streets)

shore = vect('data/raw/Shoreline.shp')
plot(shore, col='blue')

hz = vect('data/raw/SeismicHazardZones.shp')
plot(hz)

trees_df = read.csv('data/raw/Street_Tree_Map.csv')
trees = vect(trees_df, geom=c('Longitude', 'Latitude'),
             crs='EPSG:4326')

usa = ne_countries(country = 'united states of america',
                   returnclass = 'sv')

# Projecting --------------------------------------------------------------


crs(streets, describe=TRUE)
crs(shore, describe=TRUE)
crs(hz, describe=TRUE)
crs(trees, describe=TRUE)

streets_ca = project(streets, 'EPSG:3310')
shore_ca = project(shore, streets_ca)
hz_ca = project(hz, streets_ca)
trees_ca = project(trees, streets_ca)


# Cropping ----------------------------------------------------------------


streets_ext = ext(streets_ca)
shore_ca = crop(shore_ca, streets_ext)
trees_ca = crop(trees_ca, streets_ext)


# Function Interlude ------------------------------------------------------

plot_trees = function(geom_top, geom_bottom, 
                      poly_color='lightblue', ...) {
    plot_title = 'Street Trees in San Francisco'
    plot(geom_bottom, col=poly_color, axes=FALSE,
         main=plot_title)
    
    plot(geom_top, add=TRUE, ...)
    
} 

plot_trees(trees_ca, shore_ca, col='darkgreen',
           pch='.')


# Formatting Hazard Data --------------------------------------------------

head(hz_ca)

hz_data = read.csv('data/raw/Seismic_Hazard_Zones_Data.csv')
hz_data = unique(hz_data)

hz_ca = merge(hz_ca, hz_data, by.x='id', by.y='GEOID')


# Filtering ---------------------------------------------------------------

#filter trees
summary(trees_ca$DBH)
is_big = !is.na(trees_ca$DBH) & trees_ca$DBH> 48 & trees_ca$DBH < 384
trees_big = trees_ca[is_big, ]

#filter hazard zone for liquefaction
table(hz_ca$Zone_Type, exclude=FALSE)
is_liquid = hz_ca$Zone_Type == 'Liquefaction'
liquid = hz_ca[is_liquid, ]

plot_trees(trees_big, liquid, col='darkgreen', pch=19)


# Geoprocessing -----------------------------------------------------------

trees_liquid = intersect(trees_big, liquid)
plot_trees(trees_liquid, liquid, col='darkgreen', pch=19)

trees_100 = buffer(trees_liquid, width=66)
plot_trees(trees_100, liquid, col='red')

danger_zone = aggregate(trees_100)
plot_trees(danger_zone, liquid, col='red')

in_danger_zone = is.related(streets_ca, danger_zone, 
                            relation='intersects')

streets_ca$in_danger = in_danger_zone
streets_ca$status = ifelse(streets_ca$in_danger,
                           'Danger! Avoid!',
                           'Have a nice walk :)')


danger_title = 'Street Safety Status Under Seismic Hazards'
plot(streets_ca, 'status', col=c('#ba001e', 'grey50'),
     main=danger_title, axes=FALSE)


