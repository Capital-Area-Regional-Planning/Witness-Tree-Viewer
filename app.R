library(leaflet)
library(sf)
library(dplyr)
library(leaflet.extras)
library(leaflet.esri)
library(htmltools)
library(htmlwidgets)
library(shiny)
library(shinyjs)
library(bslib)
library(shinyWidgets)

# To deploy, run: rsconnect::deployApp()

#https://developers.arcgis.com/esri-leaflet/styles-and-data-visualization/style-vector-tiles/
#https://developers.arcgis.com/documentation/portal-and-data-services/data-services/vector-tile-services/introduction/

VectorTilePlugin <- htmlDependency("esri-leaflet-vector", "4.2.8",
                                   src = c(href = "https://unpkg.com/esri-leaflet-vector@4.2.8/dist"),
                                   script = "esri-leaflet-vector.js")

esriPlugin <- htmlDependency("leaflet.esri", "1.0.3",
                             src = c(href = "https://cdn.jsdelivr.net/leaflet.esri/1.0.3/"),
                             script = "esri-leaflet.js")

registerPlugin <- function(map, plugin) {
  map$dependencies <- c(map$dependencies, list(plugin))
  map}

speciesLegend <- read.csv("species_legend.csv")

speciesFilterChoices <- speciesLegend %>% 
  select(Species) %>% 
  mutate(index = row_number()-1,
         visible = 0)

jsCode <- "
shinyjs.refreshTrees = function(speciesVisiblity){

  let zoom = map.getZoom();

  //clear all the old layers
  //only delete the tree map layer... this is a very hacky solution, I'm sure there's a better one
  let i = 0;
  map.eachLayer((layer) => {
     if (i == 3) {
      layer.remove();
     }
    i++;
});

var treeGroup = L.layerGroup().addTo(map);

  //show the selected species
	//var trees = L.esri.Vector.vectorTileLayer('https://vectortileservices1.arcgis.com/4NZ4Ghri2AQmNOuO/arcgis/rest/services/Witness_trees_vector_tiles/VectorTileServer', {
  var trees = L.esri.Vector.vectorTileLayer('https://vectortileservices1.arcgis.com/4NZ4Ghri2AQmNOuO/arcgis/rest/services/Witness_Trees_Color/VectorTileServer', {

    style: function (style) {
      for (let i = 0; i < speciesVisiblity[0].length; i++) { 
        style.layers[i].paint['circle-opacity'] = speciesVisiblity[0][i];
        
        if (zoom <= 7) {
          style.layers[i].paint['circle-radius'] = 1;
        } else if (zoom >= 8 & zoom <= 9) {
          style.layers[i].paint['circle-radius'] = 2;
        } else if (zoom >=10 & zoom <= 11) {
          style.layers[i].paint['circle-radius'] = 3;
        } else if (zoom >= 12 & zoom <= 14) {
          style.layers[i].paint['circle-radius'] = 4;
        } else if (zoom >= 15) {
          style.layers[i].paint['circle-radius'] = 5;
        }
      }
     
      return style;
  }
  }).addTo(treeGroup);
  
}"

ui <- fluidPage(
  tags$head(includeScript("google-analytics.html")),
  useShinyjs(),
  extendShinyjs(text = jsCode, functions = c("refreshTrees")),
  card(
    card_header("Witness Trees"),
    layout_sidebar(
      sidebar = sidebar(
        bg = "lightgrey",
        "It was common practice in the 1830s for land surveyors in Wisconsin to use trees as landmarks. 
        This web map of historic survey records gives a glimpse of the canopy prior to mass European settlement in Wisconsin.
        Filter by tree species below:",
        pickerInput(
          "speciesFilter",
          "Species",
          choices = speciesFilterChoices$Species,
          multiple = T,
          options = list(`actions-box` = TRUE)
          ),
          plotOutput("legend")
        ),
      leafletOutput("map", height = "1000")
    )))

server <- function(input, output, session) {
  
  output$map <- renderLeaflet({
    leaflet() %>%
      registerPlugin(esriPlugin) %>%
      registerPlugin(VectorTilePlugin)%>%
      setView(lng =  -89.92588832576091, lat = 44.30524710735227, zoom = 7) %>% 
      addProviderTiles("CartoDB.Positron", group = "tst") %>%
      htmlwidgets::onRender("
            function(el,x) {
                map = this;
            }
        ")
  })
  
  #refresh tree layer when the species filter or zoom level changes 
  #pass in a boolean array showing which layers should be visible
  observe ({
    layerVisibility <- speciesFilterChoices %>%
      #set selected species as visible
      filter(Species %in% input$speciesFilter) %>%
      mutate(visible = 1.0) %>%
      #the unselected species
      bind_rows(speciesFilterChoices %>%
                  filter(!(Species %in% input$speciesFilter))) %>%
      arrange(index)

    js$refreshTrees(layerVisibility$visible) 
  }) %>% 
    bindEvent(c(input$speciesFilter, input$map_zoom))
  
  observe({
  output$legend <- renderPlot({
    filteredLegend <- speciesLegend %>% 
      filter(Species %in% input$speciesFilter)
    
    if (nrow(filteredLegend > 0)) {
    par(bg = "lightgrey")
    plot(NULL, xaxt='n',yaxt='n',bty='n',ylab='',xlab='', xlim=0:1, ylim=0:1)
    legend("right", legend = filteredLegend$Species, pch=16, pt.cex=1.5, cex=1,
           col = filteredLegend$Color, xpd = TRUE, ncol = 2, bg = "white")
    }
  }) })%>% 
    bindEvent(c(input$speciesFilter))
}

shinyApp(ui, server)
