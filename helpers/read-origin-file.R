# Read origin file .opj
library(Ropj)
library(here)
library(ggplot2)

library(tidyr)
library(dplyr)


full_path <- here("Documents", "Nanolino", "biosensor", "data", "v2", "AI_Test", "193", "193_MS5-MS6_16112022neg.opj")
my_file <- read.opj(file= full_path, encoding= 'latin1', tree= FALSE)

df <- my_file$Book2$`193_MS5-MS6_16112022neg`

time <- df[[1]] # time vector
measurement_values <- df[, 5:12]
val <- df[, 22]

measurement_values_long <- measurement_values %>% # long formt for ggplot
  mutate(time = time) %>%
  pivot_longer(cols = -time, names_to = "measurement_values", values_to = "value")

measurement_values_range <- range(measurement_values_long$value, na.rm = TRUE) # second axis for "val"
val_range <- range(val, na.rm = TRUE)
scale_factor <- diff(measurement_values_range) / diff(val_range) # and axis scaling 
val_scaled <- (val - min(val_range)) * scale_factor + min(measurement_values_range) 



ggplot() +
  geom_line(data = measurement_values_long, aes(x = time, y = value, color = measurement_values), size = .5) +
  geom_line(data = data.frame(time, val_scaled), aes(x = time, y = val_scaled), color = "red", size = .3) +
  scale_y_continuous(
    name = "sensor values",
    sec.axis = sec_axis(
      trans = ~ (. - min(measurement_values_range)) / scale_factor + min(val_range),
      name = "val (inj type)"
    )
  ) +
  labs(x = "time", y = "value", title = "sensor values and val") +
  scale_color_viridis_d() + 
  theme_minimal() +
  theme(legend.title = element_blank())


# print(my_file)

# View(my_file)
# View(my_file$TMP)
# View(my_file$Table1)
# View(my_file$Table2)
# View(my_file$Table3)
# View(my_file$Table4)
# View(my_file$Table5)
# View(my_file$Table6)
# View(my_file$Table7)
# View(my_file$PeltierData1)
# View(my_file$PeltierData1$`141911_10112022`)