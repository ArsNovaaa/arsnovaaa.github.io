---
layout: post
title: Leetcode
date: 2024-7-23 20:08 +0800
last_modified_at: 2025-2-27 21:08 +0800
tags: [leetcode，notes]
toc:  true
math: true
---

## 二分法
``` cpp
#include vector>
using namespace std;

// 经典二分法模板
int binarySearch(const vector<int>& nums, int target) {
    int left = 0;
    int right = nums.size() - 1; // 注意初始边界
    
    while (left <= right) { // 注意循环条件
        int mid = left + (right - left) / 2; // 防止溢出
        
        if (nums[mid] == target) {
            return mid; // 找到目标
        } else if (nums[mid]  target) {
            left = mid + 1; // 调整左边界
        } else {
            right = mid - 1; // 调整右边界
        }
    }
    return -1; // 未找到
}
```

## 合并排序
  ``` cpp
 #include <vector>
using namespace std;

template<typename T>
void mergeSort(vector<T>& arr) {
    vector<T> temp(arr.size()); // 预分配临时空间减少内存操作
    sortHelper(arr, 0, arr.size()-1, temp);
}

template<typename T>
void sortHelper(vector<T>& arr, int left, int right, vector<T>& temp) {
    if (left >= right) return;
    
    int mid = left + (right - left)/2;
    sortHelper(arr, left, mid, temp);
    sortHelper(arr, mid+1, right, temp);
    
    // 优化：当已有序时跳过合并
    if (arr[mid] <= arr[mid+1]) return;
    
    merge(arr, left, mid, right, temp);
}

template<typename T>
void merge(vector<T>& arr, int left, int mid, int right, vector<T>& temp) {
    int i = left, j = mid+1, k = 0;
    
    while (i <= mid && j <= right) {
        temp[k++] = arr[i] <= arr[j] ? arr[i++] : arr[j++];
    }
    while (i <= mid) temp[k++] = arr[i++];
    while (j <= right) temp[k++] = arr[j++];
    
    // 仅复制需要修改的部分
    for (int p = 0; p < k; p++) {
        arr[left+p] = temp[p];
    }
}
```

 ## 快速排序
 ``` cpp
#include <vector>
#include <ctime>
#include <cstdlib>

using namespace std;

class QuickSort {
public:
    void sort(vector<int>& nums) {
        if (nums.size() <= 1) return;
        srand(time(nullptr));
        quickSort(nums, 0, nums.size() - 1);
    }

private:
    // 三数取中法选择基准
    int medianOfThree(vector<int>& nums, int left, int right) {
        int mid = left + (right - left) / 2;
        if (nums[left] > nums[mid]) swap(nums[left], nums[mid]);
        if (nums[left] > nums[right]) swap(nums[left], nums[right]);
        if (nums[mid] > nums[right]) swap(nums[mid], nums[right]);
        return mid;
    }

    // 分区函数
    int partition(vector<int>& nums, int left, int right) {
        int pivotIndex = medianOfThree(nums, left, right);
        int pivot = nums[pivotIndex];
        swap(nums[pivotIndex], nums[right]);  // 将基准放到最后
        
        int i = left;
        for (int j = left; j < right; j++) {
            if (nums[j] <= pivot) {
                swap(nums[i], nums[j]);
                i++;
            }
        }
        swap(nums[i], nums[right]);
        return i;
    }

    void quickSort(vector<int>& nums, int left, int right) {
        if (left >= right) return;
        
        int pos = partition(nums, left, right);
        quickSort(nums, left, pos - 1);
        quickSort(nums, pos + 1, right);
    }
};

/* 使用示例：
vector<int> arr = {3,1,4,1,5,9,2,6};
QuickSort().sort(arr);
*/
```

 ``` cpp
#include <vector>
#include <cstdlib> // 用于rand()

using namespace std;

class QuickSelect {
public:
    int findKthLargest(vector<int>& nums, int k) {
        return quickSelect(nums, 0, nums.size()-1, nums.size()-k);
    }

private:
    int quickSelect(vector<int>& nums, int left, int right, int k_smallest) {
        if (left == right) return nums[left];
        
        // 随机选择pivot
        int pivot_index = left + rand() % (right - left + 1);
        pivot_index = partition(nums, left, right, pivot_index);
        
        if (k_smallest == pivot_index) {
            return nums[k_smallest];
        } else if (k_smallest < pivot_index) {
            return quickSelect(nums, left, pivot_index - 1, k_smallest);
        } else {
            return quickSelect(nums, pivot_index + 1, right, k_smallest);
        }
    }

    int partition(vector<int>& nums, int left, int right, int pivot_index) {
        int pivot = nums[pivot_index];
        swap(nums[pivot_index], nums[right]); // 将pivot移到末尾
        
        int store_index = left;
        for (int i = left; i < right; i++) {
            if (nums[i] < pivot) {
                swap(nums[store_index++], nums[i]);
            }
        }
        
        swap(nums[right], nums[store_index]); // 将pivot放回正确位置
        return store_index;
    }
};
```

 ## 单调栈
 ``` cpp
 #include <vector>
#include <stack>

// 正向遍历模板：寻找下一个更大元素
std::vector<int> nextGreaterElement(const std::vector<int>& nums) {
    int n = nums.size();
    std::vector<int> res(n, -1);
    std::stack<int> st; // 存储下标，保持栈底到栈顶对应值递减
    
    for (int i = 0; i < n; ++i) {
        while (!st.empty() && nums[i] > nums[st.top()]) {
            res[st.top()] = nums[i];
            st.pop();
        }
        st.push(i);
    }
    return res;
}

// 反向遍历模板：寻找上一个更小元素
std::vector<int> prevSmallerElement(const std::vector<int>& nums) {
    int n = nums.size();
    std::vector<int> res(n, -1);
    std::stack<int> st; // 存储下标，保持栈底到栈顶对应值递增
    
    for (int i = n-1; i >= 0; --i) {
        while (!st.empty() && nums[i] < nums[st.top()]) {
            res[st.top()] = nums[i];
            st.pop();
        }
        st.push(i);
    }
    return res;
}

/* 使用示例：
nums = [2,1,3,4,2,1]
nextGreater 结果：[3,3,4,-1,-1,-1]
prevSmaller 结果：[-1,-1,1,2,1,-1]
*/
```

## 单调队列
``` cpp
#include <deque>
#include <vector>

vector<int> maxSlidingWindow(vector<int>& nums, int k) {
    deque<int> dq; // 存储元素下标（维护单调递减队列）
    vector<int> result;

    for (int i = 0; i < nums.size(); ++i) {
        // 移除超出窗口范围的元素
        while (!dq.empty() && dq.front() < i - k + 1) {
            dq.pop_front();
        }

        // 维护单调递减特性
        while (!dq.empty() && nums[dq.back()] < nums[i]) {
            dq.pop_back();
        }

        dq.push_back(i);

        // 当窗口形成后记录结果
        if (i >= k - 1) {
            result.push_back(nums[dq.front()]);
        }
    }
    return result;
}
```

## 滑动窗口
``` cpp
int lengthOfLongestSubstring(string s) {
    unordered_map<char, int> charMap;
    int left = 0, maxLen = 0;
    for (int right = 0; right < s.size(); right++) {
        if (charMap.find(s[right]) != charMap.end()) {
            // 确保 left 不会回退
            left = max(left, charMap[s[right]] + 1);
        }
        charMap[s[right]] = right; // 更新字符的最新位置
        maxLen = max(maxLen, right - left + 1);
    }
    return maxLen;
}
```

## 回溯

``` cpp
#include <vector>
#include <algorithm> // 用于排序去重
using namespace std;

class Solution {
private:
    vector<vector<int>> result; // 存储结果
    vector<int> path;           // 当前路径

    // 核心回溯函数
    void backtrack(int start, vector<int>& nums, vector<bool>& used, int target) {
        // 终止条件：根据问题调整
        if (target == 0) { // 例如：组合总和问题
            result.push_back(path);
            return;
        }
        if (target < 0) return; // 剪枝

        for (int i = start; i < nums.size(); ++i) { // 组合问题用start，排列问题i从0开始
            // 剪枝条件（根据问题调整）
            // 去重：排序后跳过重复元素（需i > start）
            if (i > start && nums[i] == nums[i - 1]) continue;
            // 跳过已用元素（排列问题）
            if (used[i]) continue;

            // 做选择
            path.push_back(nums[i]);
            used[i] = true; // 标记已使用（排列问题需要）
            
            // 递归：参数根据问题调整
            // 组合问题：i+1（不可重复）或i（可重复）
            // 排列问题：无需start，但需used标记
            backtrack(i + 1, nums, used, target - nums[i]);
            
            // 撤销选择
            path.pop_back();
            used[i] = false;
        }
    }

public:
    vector<vector<int>> solveProblem(vector<int>& nums, int target) {
        vector<bool> used(nums.size(), false);
        sort(nums.begin(), nums.end()); // 若需去重，先排序
        backtrack(0, nums, used, target);
        return result;
    }
};
```

## 动态规划问题

- 带备忘录的递归
- 自下而上的迭代

- 满足这两个条件，就可以用动态规划解题。一般先写一下决策树，观察是否有相同子问题，最后自下而上找到状态转移方程。注意底部直接返回的值的设置和非法路径的及时返回，还有就是动态规划递推数组大小的设置。
