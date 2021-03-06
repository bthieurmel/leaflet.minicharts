# Copyright © 2016 RTE Réseau de transport d’électricité

#' Add or update charts on a leaflet map
#'
#' these functions add or update minicharts in a leaflet map at given coordinates:
#' they can be bar charts, pie charts or polar charts where chartdata is encoded
#' either by area or by radius.
#'
#' @param map A leaflet map object created with \code{\link[leaflet]{leaflet}}.
#' @param lng Longitude where to place the charts.
#' @param lat Lattitude where to place the charts.
#' @param chartdata A numeric matrix with number of rows equal to the number of
#'   elements in \code{lng} or \code{lat} and number of column equal to the
#'   number of variables to represent. If parameter \code{time} is set, the
#'   number of rows must be equal to the length of \code{lng} times the number
#'   of unique time steps in the data.
#' @param time A vector with length equal to the number of rows in \code{chartdata}
#'   and containing either numbers representing time indices or dates or
#'   datetimes. Each unique value must appear as many times as the others. This
#'   parameter can be used when one wants to represent the evolution of some
#'   variables on a map.
#' @param maxValues maximal absolute values of the variables to represent.
#'   It can be a vector with one value per column of \code{chartdata} or a single
#'   value. Using a single value enforces charts to use a unique scale for all
#'   variables. If it is \code{NULL}, the maximum value of \code{chartdata} is used.
#' @param type Type of chart. Possible values are \code{"bar"} for bar charts,
#'   \code{"pie"} for pie charts, \code{"polar-area"} and \code{"polar-radius"}
#'   for polar area charts where the values are represented respectively by the
#'   area or the radius of the slices. Finally it can be equal to \code{"auto"},
#'   the default. In this case, if there is only one variable to represent, the
#'   chart will be a single circle, else it is a barchart.
#' @param fillColor Used only if data contains only one column. It is the color
#'   used to fill the circles.
#' @param colorPalette Color palette to use when \code{chartdata} contains more than
#'   one column.
#' @param width maximal width of the created elements.
#' @param height maximal height of the created elements.
#' @param opacity Opacity of the chart.
#' @param showLabels Should values be displayed above chart elements.
#' @param labelText character vector containing the text content of the charts.
#'   Used only if \code{chartdata} contains only one column.
#' @param labelStyle Character string containing CSS properties to apply to the
#'   labels.
#' @param labelMinSize Minimal height of labels in pixels. When there is not
#'   enough space for labels, they are hidden.
#' @param labelMaxSize Maximal height of labels in pixels.
#' @param transitionTime Duration in milliseconds of the transitions when a
#'   property of a chart is updated.
#' @param popup Options that control popup generation.
#' @param layerId An ID variable. It is mandatoy when one wants to update some
#'   chart with \code{updateMinicharts}.
#' @param legend If TRUE and if data has column names, then a legend is
#'   automatically added to the map.
#' @param legendPosition Where should legend be placed?
#' @param timeFormat Character string used to format dates and times when
#'   argument \code{time} is a \code{Date}, \code{POSIXct} or \code{POSIXlt}
#'   object. See \code{\link[base]{strptime}} for more information.
#' @param initialTime This argument can be used to set the initial time step
#'   shown when the map is created. It is used only when argument \code{time} is
#'   set.
#' @param onChange (For power users who know javascript) A character string
#'   containing javascript code that is exexuted each time a chart is updated.
#'   See the details section to understand why and how to use this parameter.
#'
#' @details
#' Since version 0.5, the parameter \code{onChange} can be used to execute
#' some arbitrary javascript code each time a chart is updated (with
#' \code{updateMinicharts()} or when time step changes). A typical use case
#' would be to change the color of a polygon added with
#' \code{\link[leaflet]{addPolygons}} based on the data of the chart. It is even
#' possible to create an invisible chart and use it to manage the color and the
#' popup of a polygon. Here is a sample code that do that:
#'
#' \preformatted{
#'   leaflet() \%>\% addTiles() \%>\%
#'     addPolygons(data = myPolygons, layerId = myPolygons$myIds) \%>\%
#'     addMinicharts(
#'       mydata$lon, mydata$lat,
#'       time = mydata^time
#'       fillColor = mydata$color,
#'       layerId = mydata$myIds,
#'       width = 0, height = 0,
#'       onChange = "
#'         var s = this._map.layerManager.getLayer("shape", this.layerId);
#'         s.bindPopup(popup);
#'         if (opts.fillColor) {
#'           d3.select(s._path)
#'           .transition()
#'           .duration(750)
#'           .attr("fill", opts.fillColor);
#'         }"
#'     )
#'
#' }
#'
#' The following objects are available when executing the javascript code:
#' \describe{
#'   \item{this}{The current minichart object. See
#'   \url{https://rte-antares-rpackage.github.io/leaflet.minichart/-_L.Minichart_.html}
#'   for more information.
#'   }
#'   \item{opts}{The current options passed to the current minichart object.}
#'   \item{popup}{Popup html.}
#'   \item{d3}{The D3 module.}
#' }
#'
#' Here is a toy example
#'
#'
#' @return
#' The modified leaflet map object. \code{addMinicharts} add new minicharts to
#' the map. \code{updateMinicharts} updates minicharts that have already been
#' added to the map. \code{removeMinicharts} removes some specific charts from
#' the map and \code{clearMinicharts} removes all charts from the map and
#' if necessary the legend that has been automatically created.
#'
#' @examples
#' require(leaflet)
#' mymap <- leaflet() %>% addTiles() %>% addMinicharts(0, 0, chartdata = 1:3, layerId = "c1")
#'
#' mymap
#' mymap %>% updateMinicharts("c1", maxValues = 6)
#' mymap %>% updateMinicharts("c1", type="pie")
#'
#' @export
#'
addMinicharts <- function(map, lng, lat, chartdata = 1, time = NULL, maxValues = NULL, type = "auto",
                          fillColor = d3.schemeCategory10[1], colorPalette = d3.schemeCategory10,
                          width = 30, height = 30, opacity = 1, showLabels = FALSE,
                          labelText = NULL, labelMinSize = 8, labelMaxSize = 24,
                          labelStyle = NULL,
                          transitionTime = 750,
                          popup = popupArgs(),
                          layerId = NULL, legend = TRUE, legendPosition = "topright",
                          timeFormat = NULL, initialTime = NULL, onChange = NULL) {
  # Prepare options
  type <- match.arg(type, c("auto", "bar", "pie", "polar-area", "polar-radius"))
  if (is.null(layerId)) layerId <- sprintf("_minichart (%s,%s)", lng, lat)
  if (is.null(time)) time <- 1
  if (is.null(popup$labels)) popup$labels <- colnames(chartdata)

  if (showLabels) {
    if (!is.null(labelText)) labels <- labelText
    else labels <- "auto"
  } else {
    labels <- "none"
  }

  options <- .preprocessArgs(
    required = list(lng = lng, lat = lat, layerId = layerId, time = time),
    optional = list(type = type, width = width, height = height,
                    opacity = opacity, labels = labels,
                    labelMinSize = labelMinSize, labelMaxSize = labelMaxSize,
                    labelStyle = labelStyle,
                    transitionTime = transitionTime, fillColor = fillColor)
  )

  args <- .prepareJSArgs(options, chartdata, popup, onChange,
                         initialTime = initialTime, timeFormat = timeFormat)

  if (is.null(maxValues)) maxValues <- args$maxValues

  # Add minichart and font-awesome to the map dependencies
  map$dependencies <- c(map$dependencies, minichartDeps())

  map <- invokeMethod(map, data = leaflet::getMapData(map), "addMinicharts",
                      args$options, args$chartdata, maxValues, colorPalette,
                      args$timeLabels, args$initialTime, args$popupArgs, args$onChange)

  if (legend && length(args$legendLab) > 0 && args$ncol > 1) {
    legendCol <- colorPalette[(seq_len(args$ncols)-1) %% args$ncols + 1]
    map <- addLegend(map, labels = args$legendLab, colors = legendCol, opacity = 1,
                     layerId = "minichartsLegend", position = legendPosition)
  }

  map %>% expandLimits(lat, lng)
}

#' @export
#' @rdname addMinicharts
updateMinicharts <- function(map, layerId, chartdata = NULL, time = NULL, maxValues = NULL, type = NULL,
                             fillColor = NULL, colorPalette = d3.schemeCategory10,
                             width = NULL, height = NULL, opacity = NULL, showLabels = NULL,
                             labelText = NULL, labelMinSize = NULL,
                             labelMaxSize = NULL, labelStyle = NULL,
                             transitionTime = NULL, popup = NULL,
                             legend = TRUE, legendPosition = NULL,
                             timeFormat = NULL, initialTime = NULL, onChange = NULL) {

  if (!is.null(type)) {
    type <- match.arg(type, c("auto", "bar", "pie", "polar-area", "polar-radius"))
  }
  if (is.null(time)) time <- 1
  if (!is.null(chartdata) & !is.null(popup) & is.null(popup$labels)) popup$labels <- colnames(chartdata)

  if (is.null(showLabels)) {
    labels <- NULL
  } else {
    if (showLabels) {
      if (!is.null(labelText)) labels <- labelText
      else labels <- "auto"
    } else {
      labels <- "none"
    }
  }

  options <- .preprocessArgs(
    required = list(layerId = layerId, time = time),
    optional = list(type = type, width = width, height = height,
                    opacity = opacity, labels = labels,
                    labelMinSize = labelMinSize, labelMaxSize = labelMaxSize,
                    labelStyle = labelStyle,
                    labelText = labelText, transitionTime = transitionTime,
                    fillColor = fillColor)
  )

  args <- .prepareJSArgs(options, chartdata, popup, onChange,
                         initialTime = initialTime, timeFormat = timeFormat)

  # Update time slider only if data is updated
  if(is.null(chartdata)) {
    args$timeLabels <- NULL
  }

  # Update legend if required
  if (!is.null(args$chartdata)) {
    if (legend && length(args$legendLab) > 0 && args$ncols > 1) {
      legendCol <- colorPalette[(seq_len(args$ncols)-1) %% args$ncols + 1]
      map <- addLegend(map, labels = args$legendLab, colors = legendCol, opacity = 1,
                       layerId = "minichartsLegend", position = legendPosition)
    } else {
      map <- leaflet::removeControl(map, "minichartsLegend")
    }
  }

  map %>%
    invokeMethod(leaflet::getMapData(map), "updateMinicharts",
                 args$options, args$chartdata, unname(maxValues), colorPalette,
                 args$timeLabels, args$initialTime, args$popupArgs, args$legendLab, args$onChange)
}

#' @rdname addMinicharts
#' @export
removeMinicharts <- function(map, layerId) {
  invokeMethod(map, leaflet::getMapData(map), "removeMinicharts", layerId)
}

#' @rdname addMinicharts
#' @export
clearMinicharts <- function(map) {
  invokeMethod(map, leaflet::getMapData(map), "clearMinicharts") %>%
    leaflet::removeControl("minichartsLegend")
}
