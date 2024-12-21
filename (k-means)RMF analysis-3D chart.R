setwd("/Users/lixinzhu/Desktop/李馨竹-sql/Onlineretail_cohort_project")
library(plotly)

# 加载并清洗数据
data <- read.csv("OnlineRetail.csv")
data <- data[!is.na(data$CustomerID), ]

#Recency: 按客户计算最近一次消费时间 替换 Sys.Date() 为固定日期 "2012-01-01"
recency <- aggregate(data$InvoiceDate,by = list(CustomerID = data$CustomerID),FUN = max)

# 转换为日期时间格式
recency$x <- as.POSIXct(as.character(recency$x), format = "%m/%d/%Y %H:%M")
# 只需要日期部分
recency$x <- as.Date(recency$x)
# 检查转换是否成功
str(recency$x)
head(recency$x)
recency$Recency <- as.numeric(as.Date("2012-01-01") - recency$x)

# Frequency: 按客户计算消费次数
frequency <- as.data.frame(table(data$CustomerID))
names(frequency) <- c("CustomerID", "Frequency")
#这样也是计算频率哈
frequency1 <- aggregate(data$InvoiceNo, by = list(CustomerID = data$CustomerID), FUN = length)
# 重命名列名为更易读的形式
colnames(frequency) <- c("CustomerID", "Frequency")

# Monetary: 按客户计算总消费金额
monetary <- aggregate(data$Quantity * data$UnitPrice,by = list(CustomerID = data$CustomerID),FUN = sum)
names(monetary)[2] <- "Monetary"

# 合并 Recency, Frequency, Monetary 数据
rfm_data <- merge(recency, frequency, by = "CustomerID")
rfm_data <- merge(rfm_data, monetary, by = "CustomerID") 
# 查看 RFM 数据
head(rfm_data)

# 绘制 3D 散点图并添加 CustomerID 作为标签
 plot_ly(
  data = rfm_data,
  x = ~Recency,  
  y = ~Frequency,
  z = ~Monetary,
  text = ~paste("CustomerID:", CustomerID), # 悬停时显示 CustomerID
  type = "scatter3d",
  mode = "markers",
  marker = list(size = 5, color = ~Monetary, colorscale = "Viridis")
)

 
 # 删除非数值型列 'CustomerID'
 rfm_data_numeric <- rfm_data[, c("Recency", "Frequency", "Monetary")]

 # 标准化数据
 rfm_data_scaled <- scale(rfm_data_numeric)
 # 执行 K-means 聚类
 kmeans_result <- kmeans(rfm_data_scaled, centers = 5)
 
 # 查看聚类结果
 rfm_data$Cluster <- kmeans_result$cluster  # 将聚类结果加入数据框
 
 library(plotly)
 
 plot_ly(rfm_data, x = ~Recency, y = ~Frequency, z = ~Monetary, color = ~factor(Cluster), 
         type = 'scatter3d', mode = 'markers')