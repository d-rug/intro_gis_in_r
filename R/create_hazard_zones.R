#' This script takes data seismic hazards in the San Francisco Area from the
#' CA Dept of Conservation, California Geological Survey (CGS) Information
#' warehouse, combines it into one data set clips that data set to San Francisco
#' City/County and save the data set to a GeoJSON. This script is only concerned
#' with hazards from liquefaction and landslides but the downloaded data also 
#' contains fault zones.
#' 
#' Seismic hazard zones source data, download San Francisco, North, South,
#' Oakland West, and hunter's point from the URL below. Unzip all folders and
#' move them into intro_gis_in_r/data/setup/
#' 
#' https://maps.conservation.ca.gov/cgs/informationwarehouse/regulatorymaps/#data_s=id%3AdataSource_3-19030d1c028-layer-3%3A438



library('sf')
library('dplyr')
library('tigris')
library('geodata')

options(tigris_use_cache = TRUE)

geodata_path('data/geodata/')


import_sf_tigris = function() {
  ca_counties = counties(state='06', year=2022)
  
  san_fran_nad = ca_counties[ca_counties$NAME == 'San Francisco', ]
  
  san_fran_ta = st_transform(san_fran_nad, crs=3310)
  
  san_fran_ta = san_fran_ta[, c('GEOID', 'NAME', 'geometry')]
  
  return(san_fran_ta)
}

import_sf_gadm = function() {
  usa_sv = gadm('USA', level=2)
  
  sf_sv = usa_sv[usa_sv$NAME_2 == 'San Francisco', ]
  
  sf_sf = st_as_sf(sf_sv)
  
  sf_ta = st_transform(sf_sf, crs=3310)
  
  sf_ta = sf_ta[, c('GID_2', 'NAME_2', 'geometry')]
  
  return(sf_ta)
  
}

import_san_francisco = function() {
  
  sf_gadm = import_sf_gadm()
  
  sf_census = import_sf_tigris()
  
  san_francisco = st_crop(sf_census, sf_gadm) 
  
}

create_id = function(df, hazard) {
  quad = gsub(' ', '_', df$quad_name)
  
  slug = paste(quad, hazard, 1:nrow(df), sep='_')
  
  return(slug)
  
}

import_hz = function(fn) {
  x = st_read(fn, quiet=TRUE)
  
  names(x) <- tolower(names(x))
  
  if (grepl('liquefaction', fn)) {
    hazard_type = 'liquefaction'
  } else {
    hazard_type = 'landslide'
  }
  
  x$id = create_id(x, hazard_type)
  
  x$hazard = hazard_type
  
  vars = c('id', 'quad_name', 'hazard', 'released', 'revised', 'prev_dates',
           'comments', 'geometry')
  
  return(x[, vars])
}

hz_fns = list.files(path='data/setup', pattern='(e|n)_zone\\.shp$', 
                    recursive=TRUE, full.names=TRUE)


hz_list = lapply(hz_fns, import_hz)

hz = bind_rows(hz_list)

sf_boundary = import_san_francisco()

hz_sf = st_intersection(hz, sf_boundary)

st_write(hz_sf, 'data/raw/seismic_hazard_zones_san_francisco.geojson')

plot(hz_sf[, c('hazard')])

