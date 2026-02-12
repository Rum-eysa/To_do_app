const User = require('./User');
const Todo = require('./Todo');

User.hasMany(Todo, { foreignKey: 'userId', onDelete: 'CASCADE' });
Todo.belongsTo(User, { foreignKey: 'userId' });

module.exports = { User, Todo };
