const { Todo } = require('../models');

const getTodos = async (req, res) => {
  try {
    const todos = await Todo.findAll({
      where: { userId: req.user.id },
      order: [['createdAt', 'DESC']]
    });
    res.json(todos);
  } catch (error) {
    console.error('Get todos error:', error);
    res.status(500).json({ message: 'Server error' });
  }
};

const getTodo = async (req, res) => {
  try {
    const todo = await Todo.findOne({
      where: {
        id: req.params.id,
        userId: req.user.id
      }
    });

    if (!todo) {
      return res.status(404).json({ message: 'Todo not found' });
    }

    res.json(todo);
  } catch (error) {
    console.error('Get todo error:', error);
    res.status(500).json({ message: 'Server error' });
  }
};

const createTodo = async (req, res) => {
  try {
    const { title, description, priority, dueDate } = req.body;

    const todo = await Todo.create({
      title,
      description: description || '',
      priority: priority || 'medium',
      dueDate: dueDate || null,
      userId: req.user.id
    });

    res.status(201).json(todo);
  } catch (error) {
    console.error('Create todo error:', error);
    res.status(500).json({ message: 'Server error' });
  }
};

const updateTodo = async (req, res) => {
  try {
    const todo = await Todo.findOne({
      where: {
        id: req.params.id,
        userId: req.user.id
      }
    });

    if (!todo) {
      return res.status(404).json({ message: 'Todo not found' });
    }

    const { title, description, completed, priority, dueDate } = req.body;

    await todo.update({
      title: title || todo.title,
      description: description !== undefined ? description : todo.description,
      completed: completed !== undefined ? completed : todo.completed,
      priority: priority || todo.priority,
      dueDate: dueDate || todo.dueDate
    });

    res.json(todo);
  } catch (error) {
    console.error('Update todo error:', error);
    res.status(500).json({ message: 'Server error' });
  }
};

const deleteTodo = async (req, res) => {
  try {
    const todo = await Todo.findOne({
      where: {
        id: req.params.id,
        userId: req.user.id
      }
    });

    if (!todo) {
      return res.status(404).json({ message: 'Todo not found' });
    }

    await todo.destroy();
    res.json({ message: 'Todo removed' });
  } catch (error) {
    console.error('Delete todo error:', error);
    res.status(500).json({ message: 'Server error' });
  }
};

const toggleTodo = async (req, res) => {
  try {
    const todo = await Todo.findOne({
      where: {
        id: req.params.id,
        userId: req.user.id
      }
    });

    if (!todo) {
      return res.status(404).json({ message: 'Todo not found' });
    }

    await todo.update({
      completed: !todo.completed
    });

    res.json(todo);
  } catch (error) {
    console.error('Toggle todo error:', error);
    res.status(500).json({ message: 'Server error' });
  }
};

module.exports = {
  getTodos, getTodo, createTodo, updateTodo, deleteTodo, toggleTodo
};
