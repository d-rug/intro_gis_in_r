# Intro to GIS in R
An introduction to doing Geographic Information Science in R

## Setup

### Before the Workshop

For this workshop you will need to download R, which you can do on [CRAN][cran]
(the Comprehensive R Archive Network). It will also be a lot easier if you
download RStudio, which you can do [here][posit]. As a note, RStudio is free and
if you are being asked for payment, you are trying to download the wrong
version.

[cran]: https://cran.r-project.org/
[posit]: https://posit.co/download/rstudio-desktop/

### During the Workshop

The first thing we need to do is set up our workspace. We are going to do this
with RStudio, but you can accomplish the same thing using the R GUI. 

  1. Go to File -> New Project, or click on the Project button in the upper right
  hand corner of the window and select "New Project"
  2. Select "New Directory" unless you have git installed, in which case you can
  select "Version Control".
  3. Project Setup for "New Directory"
      a. Select "New Project" for Project Type
      b. Give your directory a name (ex. 'intro_gis_in_r')
      c. Browse and select where you want to create your new directory
      d. Click "Create Project".
      e. Navigate to the Files tab in RStudio and click "New Folder", and name
    that folder "data".
      f. Navigate inside that folder and create another folder named "raw".
  4. Project Setup for "Version Control"
      a. Select "Git".
      b. Click on the green "Code" button and copy the URL.
      c. Paste the URL into the Repository URL box.
      d. Copy the repository name and paste it into the project directory name
      box.
      e. Browse and select the directory where you want to store this project.
      f. Click "Create Project".

Next we need to install several packages. We can do that by running the
following code in the R Console.

```
install.packages('sf', 'terra', 'geodata')
```

Finally we need to download the data. The data for this workshop is stored on
Box and can be downloaded using this link. Once you have downloaded the data,
unzip the folder and move it into the `data/raw` folder in your project
directory.

Now you are ready to start coding! All of the code can be found in
`R/intro_gis.R`. Additionally Elise will save the code she writes during the
workshop as `R/intro_gis_live.R` and upload it after the workshop.

## Vector GIS in R

## Raster GIS in R
