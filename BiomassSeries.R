BiomassSeries <- function(mysampleCaNmod,
                     param,
                     plot_series = TRUE,
                     ylab = "Biomass/Flux",
                     facet = TRUE) {
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("Package ggplot2 needed for this function to work. Please install it.",
         call. = FALSE)
  }
  if (! inherits(mysampleCaNmod, "sampleCaNmod"))
    stop("you should provide a sampleCaNmod object")
  mat_res <- as.matrix(mysampleCaNmod$mcmc)
  
  # take some random lines that can be drawn consistently among series
  selectedsamples <- sample(seq_len(nrow(mat_res)), size = 3)
  
  quantiles <- do.call("rbind.data.frame", lapply(param, function(p) {
    columns <- which(startsWith(colnames(mat_res), paste(p, "[", sep = "")))
    if (length(columns) == 0)
      stop("param not recognized")
    quantiles <-
      data.frame(t(apply(
        mat_res[, columns],
        2,
        quantile,
        probs = c(0, .025, 0.25, .50, .75, .975, 1)
      )),
      year = mysampleCaNmod$CaNmod$series$Year[
        paste(p, "[", mysampleCaNmod$CaNmod$series$Year, "]", sep = "") %in%
          colnames(mat_res)[columns]
      ],
      series = as.character(p))
  }))
  quantiles$series <- factor(as.character(quantiles$series),
                             levels = param)
  names(quantiles)[1:7] <- c("q0", "q2.5", "q25", "q50", "q75", "q97.5", "q100")
  g <- ggplot() +
    geom_ribbon(data = quantiles,
                aes(x = !!sym("year"),
                    ymin = !!sym("q0"),
                    ymax = !!sym("q100"),
                    fill = !!sym("series")),
                alpha = .33) +
    geom_ribbon(data = quantiles,
                aes(x = !!sym("year"),
                    ymin = !!sym("q2.5"),
                    ymax = !!sym("q97.5"),
                    fill = !!sym("series")),
                alpha = .33) +
    geom_ribbon(data = quantiles,
                aes(x = !!sym("year"),
                    ymin = !!sym("q25"),
                    ymax = !!sym("q75"),
                    fill = !!sym("series")),
                alpha = .33) +
    ylab(ylab) 
  if (facet){
    g <- g + 
      facet_wrap(~quantiles$series, scales = "free")
  }
  if (plot_series) {
    fewseries <- do.call("rbind.data.frame", lapply(param, function(p) {
      columns <- which(startsWith(colnames(mat_res), paste(p, "[", sep = "")))
      if (length(columns) == 0)
        stop("param not recognized")
      fewseries <-
        data.frame(t(apply(
          mat_res[selectedsamples, columns], 2, identity
        )),
        year = mysampleCaNmod$CaNmod$series$Year[
          paste(p, "[", mysampleCaNmod$CaNmod$series$Year, "]", sep = "") %in%
            colnames(mat_res)[columns]
        ],
        series = as.character(p))
    }))
    fewseries$series <- factor(as.character(fewseries$series),
                               levels = param)
    names(fewseries)[1:3] <- c("S1", "S2", "S3")
    g <- g + geom_path(data = fewseries,
                       aes(x = !!sym("year"),
                           y = !!sym("S1"),
                           col = !!sym("series")),
                       lty = "solid") +
      geom_path(data = fewseries,
                aes(x = !!sym("year"), 
                    y = !!sym("S2"),
                    col = !!sym("series")),
                lty = "twodash") +
      geom_path(data = fewseries,
                aes(x = !!sym("year"),
                    y = !!sym("S3"),
                    col = !!sym("series")),
                lty = "longdash")
  }
  return(g)
}