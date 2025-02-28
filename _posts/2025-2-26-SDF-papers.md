---
layout: post
title: SDF papers
date: 2025-2-23 20:08 +0800
last_modified_at: 2025-2-27 21:08 +0800
tags: [SDF, Interactive simulation, Notes]
toc:  true
math ：true
---
最近在读两篇关于SDF应用的论文，做一些简单记录。
{: .message }

## Local Optimization for Robust Signed Distance Field Collision
英伟达20年的论文，这篇文章主要探讨了如何通过局部优化方法来实现稳健的有符号距离场（SDF）碰撞检测。具体来说，<mark>作者提出了一种基于网格元素（如三角形面和边）的局部优化方法，以找到SDF等值面与网格元素之间的最近点。</mark>这种方法可以生成精确的接触点，适用于处理尖锐特征和平滑变化的边缘-边缘接触。文章还比较了三种数值方法来解决局部优化问题：投影梯度下降法、Frank-Wolfe算法和黄金分割搜索法。实验结果表明，该方法在模拟布料、刚体和可变形固体的碰撞时表现良好，并且在许多情况下，性能方面并不比简单的点采样方法差很多。
- 特别地，我关注到这篇文章提到在解变形物体碰撞时，可以将SDF与可变形笼结合的方式来快速计算碰撞点对。
$$\phi_d = \phi_m(g(x_s))$$

这里：
$\phi_d$ 表示变形后的距离场。
$\phi_m$ 是在材料空间中定义的（静态）距离场。
$g(x_s)$ 是从世界空间到材料空间的映射函数。
