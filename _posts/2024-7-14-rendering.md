---
layout: post
title: 渲染相关
date: 2024-3-10 10:48 +0800
last_modified_at: 2024-7-27 21:08 +0800
tags: [Rendering, Notes]
toc:  false
---
<script>
MathJax = {
  tex: {
    inlineMath: [['$', '$'], ['\\(', '\\)']]
  }
};
</script>
## 渲染基础

### 蒙特卡洛积分

1. 大数定律
当样本数N->∞时，样本均值依概率收敛到期望值。
2. 构造估计量
$ \frac{1}{N} \sum_{1}^{N} \frac{f(x)}{p(x)} $ 
3. 蒙特卡洛积分公式
$ \int_{a}^{b} f(x) dx \approx \frac{1}{N} \sum_{1}^{N} \frac{f(x_i)}{p(x_i)} $


### 蒙特卡洛方法算渲染方程
- 半球采样，p(x) = 1/2pi