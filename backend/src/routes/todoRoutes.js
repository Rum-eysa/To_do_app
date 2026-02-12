const express = require('express');
const router = express.Router();
const { 
  getTodos, getTodo, createTodo, 
  updateTodo, deleteTodo, toggleTodo 
} = require('../controllers/todoController');
const { protect } = require('../middleware/auth');

router.use(protect);
router.route('/').get(getTodos).post(createTodo);
router.route('/:id').get(getTodo).put(updateTodo).delete(deleteTodo);
router.patch('/:id/toggle', toggleTodo);

module.exports = router;
