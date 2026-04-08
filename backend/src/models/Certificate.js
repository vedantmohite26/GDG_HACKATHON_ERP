const { DataTypes } = require('sequelize');

module.exports = (sequelize) => {
  const Certificate = sequelize.define('Certificate', {
    certificate_id: {
      type: DataTypes.UUID,
      defaultValue: DataTypes.UUIDV4,
      primaryKey: true
    },
    student_uid: {
      type: DataTypes.STRING,
      allowNull: false,
      index: true
    },
    student_name: {
      type: DataTypes.STRING,
      allowNull: false
    },
    student_id: {
      type: DataTypes.STRING,
      allowNull: false
    },
    course: {
      type: DataTypes.STRING,
      allowNull: false
    },
    semester: {
      type: DataTypes.STRING,
      allowNull: false
    },
    cgpa: {
      type: DataTypes.FLOAT,
      allowNull: false
    },
    sgpa: {
      type: DataTypes.FLOAT,
      allowNull: false
    },
    issued_date: {
      type: DataTypes.DATE,
      defaultValue: DataTypes.NOW
    },
    digital_signature: {
      type: DataTypes.TEXT,
      allowNull: false,
      comment: 'RSA signature of certificate data'
    },
    certificate_hash: {
      type: DataTypes.STRING,
      allowNull: false,
      unique: true,
      comment: 'SHA-256 hash of certificate content'
    },
    metadata: {
      type: DataTypes.JSONB,
      defaultValue: {},
      comment: 'Additional certificate data (subjects, etc.)'
    },
    is_revoked: {
      type: DataTypes.BOOLEAN,
      defaultValue: false
    },
    revoked_at: {
      type: DataTypes.DATE,
      allowNull: true
    },
    revoke_reason: {
      type: DataTypes.TEXT,
      allowNull: true
    }
  }, {
    tableName: 'certificates',
    timestamps: true,
    indexes: [
      { fields: ['student_uid'] },
      { fields: ['certificate_hash'], unique: true },
      { fields: ['issued_date'] }
    ]
  });

  return Certificate;
};
