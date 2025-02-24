<h1>Witness Tree Viewer</h1>

Live version: https://capital-area-rpc.shinyapps.io/witness_trees_vector_tiles/

A map of pre-European settlement trees across Wisconsin. This viewer allows users to explore a map of pre-European settlement trees across Wisconsin and filter by species. The data source is the <a href="https://search.library.wisc.edu/digital/AWILandInv">Wisconsin Land Economic Inventory (Bordner Survey)</a>.

The major challenge of this project was to create a stable, responsive, and interactive map with over 400,000 points. Applications built respectively with the mapdeck and leafletGL libraries gave promising results locally, but were not stable on Posit cloud hosting (Shinyapps.io). An ESRI application was stable, but not responsive. The final application uses the leaflet.esri library to dynamically change the styling of hosted vector tiles.

A future development goal is to incorporate additional filters based on other attributes in the original dataset.
