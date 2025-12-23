#include <iostream>
using namespace std;

class CircularQueue {
private:
    int* arr;
    int front;
    int rear;
    int capacity;
    int size;

public:
    // 构造函数
    CircularQueue(int k) {
        capacity = k;
        arr = new int[capacity];
        front = -1;
        rear = -1;
        size = 0;
    }

    // 析构函数
    ~CircularQueue() {
        delete[] arr;
    }

    // 入队操作
    bool enqueue(int value) {
        if (isFull()) {
            cout << "队列已满，无法入队" << endl;
            return false;
        }
        if (isEmpty()) {
            front = 0;
        }
        rear = (rear + 1) % capacity;
        arr[rear] = value;
        size++;
        return true;
    }

    // 出队操作
    bool dequeue() {
        if (isEmpty()) {
            cout << "队列为空，无法出队" << endl;
            return false;
        }
        if (front == rear) {
            front = -1;
            rear = -1;
        } else {
            front = (front + 1) % capacity;
        }
        size--;
        return true;
    }

    // 获取队首元素
    int Front() {
        if (isEmpty()) {
            cout << "队列为空" << endl;
            return -1;
        }
        return arr[front];
    }

    // 获取队尾元素
    int Rear() {
        if (isEmpty()) {
            cout << "队列为空" << endl;
            return -1;
        }
        return arr[rear];
    }

    // 检查队列是否为空
    bool isEmpty() {
        return size == 0;
    }

    // 检查队列是否已满
    bool isFull() {
        return size == capacity;
    }

    // 获取队列当前大小
    int getSize() {
        return size;
    }
};

// 测试用例
int main() {
    CircularQueue q(5);
    
    q.enqueue(1);
    q.enqueue(2);
    q.enqueue(3);
    q.enqueue(4);
    q.enqueue(5);
    q.enqueue(6); // 应显示队列已满
    
    cout << "队首元素: " << q.Front() << endl; // 1
    cout << "队尾元素: " << q.Rear() << endl;  // 5
    
    q.dequeue();
    q.enqueue(6);
    
    cout << "队首元素: " << q.Front() << endl; // 2
    cout << "队尾元素: " << q.Rear() << endl;  // 6
    
    return 0;
}
