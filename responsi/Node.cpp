#include "Node.h"
#include <algorithm>


template <typename T>
Node<T>::Node() : parent(nullptr), prev(nullptr), next(nullptr), size(0) {}

template <typename T>
Node<T>::~Node() {
    keys.clear();
    children.clear();
    vals.clear();
    prev = nullptr;
    next = nullptr;
    parent = nullptr;
}

template <typename T>
int Node<T>::findKey(int key) {
    int l = 0;
    int r = static_cast<int>(keys.size()) - 1;

    while (l <= r) {
        int mid = (l + r) >> 1;

        if (keys[mid] == key) {
            return mid;
        } else if (keys[mid] < key) {
            l = mid + 1;
        } else {
            r = mid - 1;
        }
    }

    return -1;
}

template <typename T>
int Node<T>::keyInsertIndex(int key) {
    return static_cast<int>(std::upper_bound(keys.begin(), keys.end(), key) - keys.begin());
}

template <typename T>
int Node<T>::indexOfChild(Node<T>* child) {
    for (size_t i = 0; i < children.size(); i++) {
        if (children[i] == child) {
            return static_cast<int>(i);
        }
    }
    return -1;
}

template <typename T>
void Node<T>::removeFromLeaf(int key) {
    int index = findKey(key);

    if (index == -1) {
        return;
    }

    keys.erase(keys.begin() + index);
    vals.erase(vals.begin() + index);
    size--;

    if (parent && !keys.empty()) {
        int idx = parent->indexOfChild(this);
        if (idx > 0) {
            parent->keys[idx - 1] = keys.front();
        }
    }
}

template <typename T>
void Node<T>::removeFromInternal(int key) {
    int index = findKey(key);

    if (index == -1) {
        return;
    }

    Node<T>* leftMostLeaf = children[index];

    while (leftMostLeaf->type != NodeType::NODE_LEAF) {
        leftMostLeaf = leftMostLeaf->children.front();
    }

    int replacementKey = leftMostLeaf->keys.front();
    T replacementVal = leftMostLeaf->vals.front();
    keys[index] = replacementKey;
    leftMostLeaf->removeFromLeaf(replacementKey);
}


template <typename T>
void Node<T>::borrowFromRightLeaf() {
    Node<T>* nextNode = this->next;
    if (!nextNode || nextNode->keys.empty() || !parent)
        return;

    keys.push_back(nextNode->keys.front());
    vals.push_back(nextNode->vals.front());

    nextNode->keys.erase(nextNode->keys.begin());
    nextNode->vals.erase(nextNode->vals.begin());

    size++;
    nextNode->size--;

    int childIndex = parent->indexOfChild(this);
    if (childIndex >= 0 && childIndex < parent->keys.size()) {
        parent->keys[childIndex] = nextNode->keys.front();
    }
}

template <typename T>
void Node<T>::borrowFromLeftLeaf() {
    Node<T>* prevNode = this->prev;
    if (!prevNode || prevNode->keys.empty() || !parent)
        return;

    keys.insert(keys.begin(), prevNode->keys.back());
    vals.insert(vals.begin(), prevNode->vals.back());

    prevNode->keys.pop_back();
    prevNode->vals.pop_back();

    size++;
    prevNode->size--;

    int childIndex = parent->indexOfChild(this);
    if (childIndex > 0 && childIndex <= parent->keys.size()) {
        parent->keys[childIndex - 1] = keys.front();
    }
}


template <typename T>
void Node<T>::mergeWithRightLeaf() {
    Node<T>* nextNode = this->next;
    if (!nextNode || !parent)
        return;

    for (size_t i = 0; i < nextNode->keys.size(); i++) {
        keys.push_back(nextNode->keys[i]);
        vals.push_back(nextNode->vals[i]);
        size++;
    }

    this->next = nextNode->next;
    if (this->next) {
        this->next->prev = this;
    }

    int childIndex = parent->indexOfChild(nextNode);
    if (childIndex > 0) {
        parent->keys.erase(parent->keys.begin() + (childIndex - 1));
        parent->size--;
    }

    parent->children.erase(std::find(parent->children.begin(), parent->children.end(), nextNode));

    delete nextNode;
}

template <typename T>
void Node<T>::mergeWithLeftLeaf() {
    Node<T>* prevNode = this->prev;
    if (!prevNode || !parent)
        return;

    for (size_t i = 0; i < keys.size(); i++) {
        prevNode->keys.push_back(keys[i]);
        prevNode->vals.push_back(vals[i]);
        prevNode->size++;
    }

    prevNode->next = this->next;
    if (prevNode->next) {
        prevNode->next->prev = prevNode;
    }

    int childIndex = parent->indexOfChild(this);
    if (childIndex > 0) {
        parent->keys.erase(parent->keys.begin() + (childIndex - 1));
        parent->size--;
    }
    parent->children.erase(std::find(parent->children.begin(), parent->children.end(), this));
}


template <typename T>
void Node<T>::borrowFromRightInternal(Node<T>* nextNode) {
    if (!nextNode || !parent)
        return;

    int childIndex = parent->indexOfChild(this);
    if (childIndex < 0) return;

    keys.push_back(parent->keys[childIndex]);
    parent->keys[childIndex] = nextNode->keys.front();
    nextNode->keys.erase(nextNode->keys.begin());

    size++;
    nextNode->size--;

    if (!nextNode->children.empty()) {
        Node<T>* childToMove = nextNode->children.front();
        nextNode->children.erase(nextNode->children.begin());
        
        children.push_back(childToMove);
        childToMove->parent = this;
    }
}

template <typename T>
void Node<T>::borrowFromLeftInternal(Node<T>* prevNode) {
    if (!prevNode || !parent)
        return;

    int childIndex = parent->indexOfChild(this);
    if (childIndex <= 0) return;

    keys.insert(keys.begin(), parent->keys[childIndex - 1]);
    parent->keys[childIndex - 1] = prevNode->keys.back();
    prevNode->keys.pop_back();

    size++;
    prevNode->size--;

    if (!prevNode->children.empty()){
        Node<T>* childToMove = prevNode->children.back();
        prevNode->children.pop_back();
        children.insert(children.begin(), childToMove);
        childToMove->parent = this;
    }
}

template <typename T>
void Node<T>::mergeWithRightInternal(Node<T>* nextNode) {
    if (!nextNode || !parent)
        return;

    int childIndex = parent->indexOfChild(this);
    if (childIndex < 0) return;

    keys.push_back(parent->keys[childIndex]);
    parent->keys.erase(parent->keys.begin() + childIndex);
    parent->size--;

    for (int key : nextNode->keys) {
        keys.push_back(key);
    }

    size = keys.size();

    for (Node<T>* child : nextNode->children) {
        children.push_back(child);
        child->parent = this;
    }

    parent->children.erase(parent->children.begin() + childIndex + 1);

    delete nextNode;
}

template <typename T>
void Node<T>::mergeWithLeftInternal(Node<T>* prevNode) {
    if (!prevNode || !parent)
        return;

    int childIndex = parent->indexOfChild(this);
    if (childIndex <= 0) return;

    prevNode->keys.push_back(parent->keys[childIndex - 1]);
    parent->keys.erase(parent->keys.begin() + (childIndex - 1));
    parent->size--;

    for (int key : keys) {
        prevNode->keys.push_back(key);
    }

    prevNode->size = prevNode->keys.size();

    for (Node<T>* child : children){
        prevNode->children.push_back(child);
        child->parent = prevNode;
    }

    parent->children.erase(parent->children.begin() + childIndex);
}

template <typename T>
void Node<T>::set(int key, const T& val) {
    int keyIndex = findKey(key);

    if (keyIndex != -1) {
        vals[keyIndex] = val;
        return;
    }

    int insIndex = keyInsertIndex(key);
    keys.insert(keys.begin() + insIndex, key);
    vals.insert(vals.begin() + insIndex, val);
    size++;
}

template <typename T>
Node<T>* Node<T>::splitLeaf(int rIndex) {
    Node<T>* newSiblingNode = new Node<T>();
    newSiblingNode->type = NodeType::NODE_LEAF;
    newSiblingNode->prev = this;
    newSiblingNode->next = next;
    next = newSiblingNode;

    if (newSiblingNode->next) {
        newSiblingNode->next->prev = newSiblingNode;
    }

    for (int i = size - 1; i >= rIndex; i--) {
        int key = keys[i];
        T val = vals[i];

        newSiblingNode->set(key, val);
        keys.pop_back();
        vals.pop_back();
    }

    keys.shrink_to_fit();
    children.shrink_to_fit();
    vals.shrink_to_fit();

    newSiblingNode->size = static_cast<int>(newSiblingNode->keys.size());
    size = static_cast<int>(keys.size());

    return newSiblingNode;
}

template <typename T>
Node<T>* Node<T>::splitInternal(int rIndex) {
    Node<T>* newSiblingNode = new Node<T>();
    newSiblingNode->type = NodeType::NODE_INTERNAL;

    int keysToTransfer = size - rIndex - 1;
    int childrenToTransfer = size - rIndex;
    
    newSiblingNode->keys.resize(keysToTransfer);
    newSiblingNode->children.resize(childrenToTransfer);

    for (int i = 0; i < childrenToTransfer; i++) {
        newSiblingNode->children[i] = children[rIndex + 1 + i];
        children[rIndex + 1 + i]->parent = newSiblingNode;
    }

    children.resize(rIndex + 1);

    for (int i = 0; i < keysToTransfer; i++){
        newSiblingNode->keys[i] = keys[rIndex + 1 + i];
    }
    keys.resize(rIndex);
    
    newSiblingNode->size = keysToTransfer;
    size = rIndex;

    return newSiblingNode;
}

template <typename T>
Node<T>* Node<T>::splitNode() {
    int rIndex = size >> 1;
    int newParentKey = keys[rIndex];

    Node<T>* siblingNode;

    if (type == NodeType::NODE_LEAF) {
        siblingNode = splitLeaf(rIndex);
    } else {
        siblingNode = splitInternal(rIndex);
    }

    if (parent) {
        Node<T>* parentNode = parent;

        int index = parentNode->keyInsertIndex(newParentKey);
        parentNode->keys.insert(parentNode->keys.begin() + index, newParentKey);
        parentNode->size++;

        if (index >= static_cast<int>(parentNode->children.size())) {
            parentNode->children.push_back(siblingNode);
        } else if (parentNode->children[index] != this) {
            int pos = parentNode->indexOfChild(this);
            if (pos >= 0) {
                parentNode->children.insert(parentNode->children.begin() + pos + 1, siblingNode);
            } else {
                parentNode->children.insert(parentNode->children.begin() + index + 1, siblingNode);
            }
        } else {
            parentNode->children.insert(parentNode->children.begin() + index + 1, siblingNode);
        }

        siblingNode->parent = parentNode;
    } else {
        Node<T>* newRootNode = new Node<T>();

        newRootNode->type = NodeType::NODE_ROOT;
        newRootNode->keys.push_back(newParentKey);
        newRootNode->size = 1;
        newRootNode->children.push_back(this);
        newRootNode->children.push_back(siblingNode);

        if (type == NodeType::NODE_ROOT) {
            type = NodeType::NODE_INTERNAL;
        }

        parent = newRootNode;
        siblingNode->parent = newRootNode;

        return newRootNode;
    }

    return nullptr;
}

// Explicit template instantiation for common types

template class Node<std::string>;
template class Node<int>;
template class Node<double>;