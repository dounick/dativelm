from typing import List
import pickle
from numpy import random

class Node:
    def __init__(self, text: str, constituent: str, children: List['Node'], position: int, parent_position: int, pos: str):
        self.text = text
        self.constituent = constituent
        self.children = children
        self.position = position
        self.parent_position = parent_position
        self.pos = pos

    def __repr__(self):
        return f"Node(text='{self.text}', constituent='{self.constituent}', position={self.position}, parent_position={self.parent_position})"
    
def build_node_nosort(token, visited):
    if token in visited:
        return visited[token]
    
    children = []
    for child in token.children:
        child_node = build_node_nosort(child, visited)
        children.append(child_node)
    
    left_children = sorted([c for c in children if c.position < token.i], key=lambda x: x.position)
    right_children = sorted([c for c in children if c.position > token.i], key=lambda x: x.position)
    
    parts = []
    for child in left_children:
        parts.append(child.constituent)
    parts.append(token.text)
    for child in right_children:
        parts.append(child.constituent)
    
    constituent = ' '.join(parts)
    
    node = Node(
        text=token.text,
        constituent=constituent,
        children=left_children + right_children,
        position=token.i,
        parent_position=token.head.i if token.head != token else -1,
        pos=token.pos_  # Store POS tag to identify punctuation
    )
    visited[token] = node
    return node

def build_node_random(token, visited):
    if token in visited:
        return visited[token]
    
    children = []
    for child in token.children:
        child_node = build_node_random(child, visited)
        children.append(child_node)
    
    non_punct_children = [c for c in children if c.pos != "PUNCT"]
    non_punct_sorted_positions = sorted([c.position for c in non_punct_children])
    punct_children = [c for c in children if c.pos == "PUNCT"]
    
    sorted_non_punct = sorted(
        non_punct_children,
        key=lambda x: len([word for word in x.constituent.split() if any(char.isalnum() for char in word)]),
        reverse=random.choice([True, False])
    )
    for i, child in enumerate(sorted_non_punct):
        child.position = non_punct_sorted_positions[i]
    
    children_sorted = non_punct_children + punct_children
    
    left_children = sorted([c for c in children_sorted if c.position < token.i], key=lambda x: x.position)
    right_children = sorted([c for c in children_sorted if c.position > token.i], key=lambda x: x.position)
    
    parts = []
    for child in left_children:
        parts.append(child.constituent)
    parts.append(token.text)
    for child in right_children:
        parts.append(child.constituent)
    
    constituent = ' '.join(parts)
    
    node = Node(
        text=token.text,
        constituent=constituent,
        children=left_children + right_children,
        position=token.i,
        parent_position=token.head.i if token.head != token else -1,
        pos=token.pos_  # Store POS tag to identify punctuation
    )
    visited[token] = node
    return node

def build_node(token, visited, short_first):
    if token in visited:
        return visited[token]
    
    children = []
    for child in token.children:
        child_node = build_node(child, visited, short_first)
        children.append(child_node)
    
    non_punct_children = [c for c in children if c.pos != "PUNCT"]
    non_punct_sorted_positions = sorted([c.position for c in non_punct_children])
    punct_children = [c for c in children if c.pos == "PUNCT"]
    
    sorted_non_punct = sorted(
        non_punct_children,
        key=lambda x: len([word for word in x.constituent.split() if any(char.isalnum() for char in word)]),
        reverse=not short_first
    )
    for i, child in enumerate(sorted_non_punct):
        child.position = non_punct_sorted_positions[i]
    
    children_sorted = non_punct_children + punct_children
    
    left_children = sorted([c for c in children_sorted if c.position < token.i], key=lambda x: x.position)
    right_children = sorted([c for c in children_sorted if c.position > token.i], key=lambda x: x.position)
    
    parts = []
    for child in left_children:
        parts.append(child.constituent)
    parts.append(token.text)
    for child in right_children:
        parts.append(child.constituent)
    
    constituent = ' '.join(parts)
    
    node = Node(
        text=token.text,
        constituent=constituent,
        children=left_children + right_children,
        position=token.i,
        parent_position=token.head.i if token.head != token else -1,
        pos=token.pos_  # Store POS tag to identify punctuation
    )
    visited[token] = node
    return node

def build_node_headfinal(token, visited):
    if token in visited:
        return visited[token]
    
    children = []
    for child in token.children:
        child_node = build_node_headfinal(child, visited)
        children.append(child_node)
    
    non_punct_children = [c for c in children if c.pos != "PUNCT"]
    non_punct_sorted_positions = sorted([c.position for c in non_punct_children])
    punct_children = [c for c in children if c.pos == "PUNCT"]
    
    sorted_non_punct = sorted(
        non_punct_children,
        key=lambda x: len([word for word in x.constituent.split() if any(char.isalnum() for char in word)]),
        reverse=True
    )
    for i, child in enumerate(sorted_non_punct):
        child.position = non_punct_sorted_positions[i]
    
    children_sorted = non_punct_children + punct_children

    if len(non_punct_sorted_positions) > 0:
        left_children = sorted([c for c in children_sorted if c.position <= non_punct_sorted_positions[-1]], key=lambda x: x.position)
        right_children = sorted([c for c in children_sorted if c.position > non_punct_sorted_positions[-1]], key=lambda x: x.position)
    else: 
        left_children = []
        right_children = [] 
    parts = []
    for child in left_children:
        parts.append(child.constituent)
    parts.append(token.text)
    for child in right_children:
        parts.append(child.constituent)

    constituent = ' '.join(parts)
    
    node = Node(
        text=token.text,
        constituent=constituent,
        children=children_sorted,
        position=non_punct_sorted_positions[-1] if len(non_punct_sorted_positions) > 0 else token.i,
        parent_position=token.head.i if token.head != token else -1,
        pos=token.pos_  # Store POS tag to identify punctuation
    )
    visited[token] = node
    return node

def reorder_sentence(doc, short_first):
    root = [token for token in doc if token.head == token][0]
    visited = {}
    root_node = build_node(root, visited, short_first)
    return root_node.constituent

def reorder_sentence_random(doc):
    root = [token for token in doc if token.head == token][0]
    visited = {}
    root_node = build_node_random(root, visited)
    return root_node.constituent

def reorder_sentence_headfinal(doc):
    root = [token for token in doc if token.head == token][0]
    visited = {}
    root_node = build_node_headfinal(root, visited)
    return root_node.constituent 

def calculate_sorting_inversions(node):
    if not node.children:
        return 0, 0, 0
    
    non_punct_children = [c for c in node.children if c.pos != "PUNCT"]
    
    node_inversions_short = 0
    node_inversions_long = 0
    node_comparisons = 0
    
    if len(non_punct_children) > 1:
        lengths = [
            len([word for word in child.constituent.split() if any(char.isalnum() for char in word)]) 
            for child in non_punct_children
        ]
        
        for i in range(len(lengths)):
            for j in range(i+1, len(lengths)):
                node_comparisons += 1
                if (lengths[i] > lengths[j]):
                    node_inversions_short += 1
                elif (lengths[i] < lengths[j]):
                    node_inversions_long += 1
    
    for child in node.children:
        child_inversions_short, child_inversions_long, child_comparisons = calculate_sorting_inversions(child)
        node_inversions_short += child_inversions_short
        node_inversions_long += child_inversions_long
        node_comparisons += child_comparisons
    
    return node_inversions_short, node_inversions_long, node_comparisons

def get_inversion_score(doc):
    root = [token for token in doc if token.head == token][0]
    visited = {}
    root_node = build_node_nosort(root, visited)
    
    node_inversions_short, node_inversions_long, node_comparisons = calculate_sorting_inversions(root_node)
        
    return {
        'short_inversions': node_inversions_short,
        'long_inversions': node_inversions_long,
        'total_comparisons': node_comparisons,
    }

def save_node_structure(node, filename):
    with open(filename, 'wb') as f:
        pickle.dump(node, f)

def load_node_structure(filename):
    with open(filename, 'rb') as f:
        return pickle.load(f)