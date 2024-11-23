
setwd("/Users/lixinzhu/Desktop/李馨竹-sql/Onlineretail_cohort_project")
# 读取数据
online_retail <- read.csv("OnlineRetail.csv")

# 查看数据结构
str(online_retail)
summary(online_retail)

#缺失值
sum(is.na(online_retail))
# 删除包含 NA 的行
Online_Retail<- na.omit(online_retail)

#将发票时间转换为日期格式 原先是character
Online_Retail$InvoiceDate <- as.POSIXct(Online_Retail$InvoiceDate, format = "%m/%d/%Y %H:%M")
str(Online_Retail)
summary(Online_Retail)

#清洗数据 从前面的summary中可以看出 数量的最小值竟然有负数
#Quantity ≤ 0：如退货（通常表示为负数量），或者无购买行为（数量为 0
#所以排除数据录入错误等，我们在这个分析中就使用>0的好了
Online_Retail <- subset(Online_Retail, Quantity > 0 & UnitPrice > 0)
Online_Retail <- subset(Online_Retail, !is.na(CustomerID))

summary(Online_Retail)

#提取首次购买月份作为 CohortMonth,并提取每个购买日的年月作为BuyingMonth，然后才能计算月份差啊！
library(zoo)
library(dplyr)

#mutate() 是 dplyr 包中的一个函数，用于添加或修改数据框中的列。它的核心功能是基于已有的列计算新列，或者更新现有列的值，而不会改变数据框的结构。

Online_Retail <- Online_Retail %>%
  group_by(CustomerID) %>%
  mutate(
    CohortMonth = format(min(InvoiceDate), "%Y-%m"),
    BuyingMonth = format(InvoiceDate, "%Y-%m")
  ) %>%
  ungroup()

#算monthdiff 没有办法去进行两个Month的相减 转换为date 类型必须是常规的年月日类型 而这里只有年月
# sql 里面是搭配timestampdiff + date()
Online_Retail <- Online_Retail %>%
  mutate(
    BuyingMonth = as.yearmon(BuyingMonth, format = "%Y-%m"),
    CohortMonth = as.yearmon(CohortMonth, format = "%Y-%m"),
    MonthDiff = round((BuyingMonth - CohortMonth) * 12)
  )


cohort_table <- Online_Retail %>%
  group_by(CohortMonth, MonthDiff) %>%                    #将数据按照 CohortMonth（客户首次购买的月份）和 MonthDiff（与首次购买月份的差值）进行分组。
  summarise(CustomerCount = n_distinct(CustomerID)) %>%
  ungroup() %>%                                             #解除之前的分组，方便后续的分组操作。
  group_by(CohortMonth) %>%                                #按 CohortMonth 重新分组，以便计算留存率。
  mutate(RetentionRate = CustomerCount / first(CustomerCount))
#first(CustomerCount): 表示当前 Cohort 在第一个月（MonthDiff == 0，即客户首次活跃的月份）的客户数量，作为该 Cohort 的基数。



#画图
library(ggplot2)

ggplot(cohort_table, aes(x = MonthDiff, y = CohortMonth, fill = RetentionRate)) +
  geom_tile(color = "white") +
  scale_fill_gradient(low = "white", high = "purple") +
  labs(title = "Cohort Retention Heatmap", x = "Month Difference", y = "Cohort")



library(ggplot2)

library(ggplot2)

ggplot(cohort_table, aes(x = MonthDiff, y = CohortMonth, fill = RetentionRate)) +
  geom_tile(color = "white") +  # 创建热力图
  geom_text(aes(label = scales::percent(RetentionRate, accuracy = 0.1)), 
            color = "black", size = 2) +  # 在格子中添加标签
  scale_fill_gradient(low = "white", high = "purple") +  # 设置颜色梯度
  labs(title = "Cohort Retention Heatmap", 
       x = "Month Difference", 
       y = "Cohort")   # 设置标题和轴标签



library(ggplot2)
library(dplyr)
cohort_table <- cohort_table %>%
  mutate(CohortMonth = as.character(CohortMonth))

ggplot(cohort_table, aes(x = MonthDiff, y = RetentionRate, color = CohortMonth, group = CohortMonth)) +
  geom_line(size = 1) +  # 添加折线
  geom_point(size = 2) +  # 在折线节点上添加点
  scale_y_continuous(labels = scales::percent_format(accuracy = 1)) +  # 留存率转换为百分比显示
  labs(
    title = "Cohort retention line chart",
    x = "monthdiff",
    y = "cohort",
    color = "Cohort"
  ) +
  theme_minimal()