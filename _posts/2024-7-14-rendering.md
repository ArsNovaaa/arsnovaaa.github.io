---
layout: post
title: 渲染相关
date: 2024-3-10 10:48 +0800
last_modified_at: 2024-7-27 21:08 +0800
tags: [Rendering, Notes]
toc:  false
math: true
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

4. 半球采样，$ p(x) = 1/2pi $

### SDF软阴影
- 场景sdf算遮挡角度
- 参数控制阴影过度区域大小

### shadow mapping
- 基于深度纹理的阴影贴图
- 阴影贴图的生成
- 阴影贴图的采样

两个pass：
光照pass：生成阴影贴图
渲染pass：使用阴影贴图渲染物体

- 有自遮挡和走样问题---引入bias容差（相关于入射角度），有会有悬空问题。

## 布林冯光照
- 冯高光 :
视方向vDir = normalize(相机位置 camPos - 顶点位置 posWS)
反射方向rDir = reflect( 视方向vDir , 法线方向nDir)
dot(视方向vDir,反射方向rDir)
拿观察方向和反射方向做点积，夹角会大于90产生硬边

- 布灵- 冯 高光:
半程方向hDir = normalize(视方向vDir + 灯光方向lDir)
dot(半程方向hDir,法线方向nDir)
拿半程方向和法线做点积