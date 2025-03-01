---
layout: post
title: SDF Papers
date: 2024-7-23 20:08 +0800
last_modified_at: 2025-2-27 21:08 +0800
tags: [SDF, Interactive simulation, Notes]
toc:  true
math: true
---
<script>
MathJax = {
  tex: {
    inlineMath: [['$', '$'], ['\\(', '\\)']]
  }
};
</script>

最近在读两篇关于SDF应用的论文，找找快速重建变形物体（基于骨架蒙皮）SDF的思路，做一些简单记录。
{: .message }

## 《Local Optimization for Robust Signed Distance Field Collision》
英伟达20年的论文，这篇文章主要探讨了如何通过局部优化方法来实现稳健的有符号距离场（SDF）碰撞检测。<具体来说，作者提出了一种基于网格元素（如三角形面和边）的局部优化方法，以找到SDF等值面与网格元素之间的最近点。这种方法可以生成精确的接触点，适用于处理尖锐特征和平滑变化的边缘-边缘接触。文章还比较了三种数值方法来解决局部优化问题：投影梯度下降法、Frank-Wolfe算法和黄金分割搜索法。实验结果表明，该方法在模拟布料、刚体和可变形固体的碰撞时表现良好，并且在许多情况下，性能方面并不比简单的点采样方法差很多。

特别地，我关注到这篇文章提到在解变形物体碰撞时，可以将SDF与可变形笼结合的方式来快速计算碰撞点对。

$$\phi_d = \phi_m(g(x_s))$$ 

这里：
$\Phi_d$ 表示变形后的距离场。
$\Phi_m$ 是在材料空间中定义的（静态）距离场。
$g(x_s)$ 是从世界空间到材料空间的映射函数(位移逆函数),给定这样的映射，我们可以定义一个变形后的距离场。

具体的流程如下：
1. 给定一个变形的四面体网格，我们首先找到世界空间点的四面体，然后计算与之相关的物质空间点。通过使用边界体积层次结构（BVH）或其他空间数据结构，可以高效地找到顶点为v0、v1、v2、v3的包围四面体。假设线性形函数，投影回到材料空间由以下给出：
$$
x_m = g(x_s) = M D^{-1} (x_s - v_{0s}) + v_{0m} 
$$ 

### 空间映射公式解析

#### 符号说明：
- **下标约定**  
  $s$: 世界空间量（spatial space）  
  $m$: 物质空间量（material space）

- **核心矩阵**  
  $D \in \mathbb{R}^{3×3}$: 变形四面体在世界空间中的基底矩阵  
  $M \in \mathbb{R}^{3×3}$: 未变形四面体在物质空间中的基底矩阵

  $$
  M = (v_{1m} - v_{0m}, v_{2m} - v_{0m}, v_{3m} - v_{0m})
  $$

  $$
  D = (v_{1s} - v_{0s}, v_{2s} - v_{0s}, v_{3s} - v_{0s})
  $$

- **参考点**  
  $v_{0s}$: 世界空间中变形四面体的原点坐标  
  $v_{0m}$: 物质空间中未变形四面体的原点坐标  
  $x_{s}$: 世界空间中在三角形上的点 $x_s(u,v,w)=up+vq+wr$

#### 运算流程：
1. **坐标平移**  
   $x_s - v_{0s}$: 将世界空间坐标平移到以变形四面体原点为基准

2. **基底变换**  
   $D^{-1}$: 通过逆基底矩阵将坐标转换到规范空间

3. **物质空间映射**  
   $M D^{-1}$: 组合变换矩阵，将规范空间坐标映射到物质空间

4. **最终平移**  
   $+ v_{0m}$: 将结果平移回物质空间坐标系

在最终得到$\phi_d$后，根据文章提出的三种数值解法中都需要得到这个sdf函数的梯度，这里关于变形物体sdf的梯度可表示为

$$
 d = \begin{bmatrix} \frac{\partial \phi_d}{\partial u} \ \frac{\partial \phi_d}{\partial v} \ \frac{\partial \phi_d}{\partial w} \end{bmatrix}^T = \begin{bmatrix} \nabla \phi_m(x_m) G(x_s)_p \ \nabla \phi_m(x_m) G(x_s)_q \ \nabla \phi_m(x_m) G(x_s)_r \end{bmatrix}^T 
$$

这种方法的一个关键优势是它将弹性离散化与碰撞表示解耦。这使其可以用规则且相对粗糙的六面体网格（分解为四面体）来计算内部弹性动力学，同时使用高分辨率 SDF 表示来解决碰撞。

## 《Bounding Volume Hierarchies Centric Adaptive Distance Field Computation for Deformable Objects on GPUs》
主要介绍了BADF（基于包围体层次结构的自适应距离场计算）算法，这是一种用于加速刚性和可变形模型在图形处理单元（GPU）上构建自适应距离场（ADFs）的新方法，它通过构造包围体层次结构（BVH），并利用该层次结构生成基于八叉树的自适应距离场。该算法还利用了帧间的一致性来加速计算。对BVH的并行快速构建，使用了Morton码，具体算法流程可以参考09年EG上的《Fast BVH Construction on GPUs》这篇文章。
### 基于BVH生成八叉树的实现原理

#### 核心参数说明
- **δ值**：表示Morton码前缀长度或节点深度，每个层级对应三维空间的细分
- **3整除规则**：每3位Morton码对应八叉树的一个层级划分（X/Y/Z各1位）

#### 构建流程步骤

1. **BVH预处理**
   - 为所有节点计算Morton码
   - 记录每个节点的δ值（编码长度/深度层级）

2. **层级映射规则**

   {% highlight cpp %}
    int GetOctreeLevel(int delta) {
        return delta / 3; // 每3位对应一个八叉树层级
    }
   {% endhighlight %}

3. 节点生成规则

    - 当满足：(child.delta/3 - parent.delta/3) > 0 时
    - 生成中间八叉树节点
    - 示例：
        父节点 δ=3 → Level 1
        子节点 δ=6 → Level 2
        差值=3 → 需要生成Level 2的八叉树节点。

4. 空间转换关系

   - 二进制：ZYXZYX... 
   - 每3位对应： 
      bit2 - Z轴方位 (0:负向, 1:正向)
      bit1 - Y轴方位
      bit0 - X轴方位

### 根据八叉树实现快速ADF查询

对每个八叉树网格点执行距离查询以构建最终距离场。分配每个角点一个Morton码，确保每个角点只有一个查询。

### 一些想法
应用变形映射生成Voronoi图（A simple GPU-based approach for 3D Voronoi diagram construction and visualization IEEE 2005），再生成SDF。
直接在八叉树结构下的ADF角点应用变形映射？代替可变形笼（四面体网格）。