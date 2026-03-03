// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'models.dart';

// **************************************************************************
// LoxiaEntityGenerator
// **************************************************************************

final EntityDescriptor<User, UserPartial> $UserEntityDescriptor =
    EntityDescriptor(
      entityType: User,
      tableName: 'users',
      columns: [
        ColumnDescriptor(
          name: 'id',
          propertyName: 'id',
          type: ColumnType.integer,
          nullable: false,
          unique: false,
          isPrimaryKey: true,
          autoIncrement: true,
          uuid: false,
        ),
        ColumnDescriptor(
          name: 'email',
          propertyName: 'email',
          type: ColumnType.text,
          nullable: false,
          unique: false,
          isPrimaryKey: false,
          autoIncrement: false,
          uuid: false,
        ),
        ColumnDescriptor(
          name: 'role',
          propertyName: 'role',
          type: ColumnType.text,
          nullable: false,
          unique: false,
          isPrimaryKey: false,
          autoIncrement: false,
          uuid: false,
        ),
        ColumnDescriptor(
          name: 'tags',
          propertyName: 'tags',
          type: ColumnType.json,
          nullable: false,
          unique: false,
          isPrimaryKey: false,
          autoIncrement: false,
          uuid: false,
        ),
      ],
      relations: const [
        RelationDescriptor(
          fieldName: 'posts',
          type: RelationType.oneToMany,
          target: Post,
          isOwningSide: false,
          mappedBy: 'user',
          fetch: RelationFetchStrategy.lazy,
          cascade: const [RelationCascade.persist],
          cascadePersist: true,
          cascadeMerge: false,
          cascadeRemove: false,
        ),
      ],
      fromRow: (row) => User(
        id: (row['id'] as int),
        email: (row['email'] as String),
        role: Role.values.byName(row['role'] as String),
        tags: (decodeJsonColumn(row['tags']) as List).cast<String>(),
        posts: const <Post>[],
      ),
      toRow: (e) => {
        'id': e.id,
        'email': e.email,
        'role': e.role.name,
        'tags': encodeJsonColumn(e.tags),
      },
      fieldsContext: const UserFieldsContext(),
      repositoryFactory: (EngineAdapter engine) => UserRepository(engine),
      defaultSelect: () => UserSelect(),
    );

class UserFieldsContext extends QueryFieldsContext<User> {
  const UserFieldsContext([super.runtimeContext, super.alias]);

  @override
  UserFieldsContext bind(QueryRuntimeContext runtimeContext, String alias) =>
      UserFieldsContext(runtimeContext, alias);

  QueryField<int> get id => field<int>('id');

  QueryField<String> get email => field<String>('email');

  QueryField<Role> get role => field<Role>('role');

  QueryField<List<String>> get tags => field<List<String>>('tags');

  /// Find the owning relation on the target entity to get join column info
  PostFieldsContext get posts {
    final targetRelation = $PostEntityDescriptor.relations.firstWhere(
      (r) => r.fieldName == 'user',
    );
    final joinColumn = targetRelation.joinColumn!;
    final alias = ensureRelationJoin(
      relationName: 'posts',
      targetTableName: $PostEntityDescriptor.qualifiedTableName,
      localColumn: joinColumn.referencedColumnName,
      foreignColumn: joinColumn.name,
      joinType: JoinType.left,
    );
    return PostFieldsContext(runtimeOrThrow, alias);
  }
}

class UserQuery extends QueryBuilder<User> {
  const UserQuery(this._builder);

  final WhereExpression Function(UserFieldsContext) _builder;

  @override
  WhereExpression build(QueryFieldsContext<User> context) {
    if (context is! UserFieldsContext) {
      throw ArgumentError('Expected UserFieldsContext for UserQuery');
    }
    return _builder(context);
  }
}

class UserSelect extends SelectOptions<User, UserPartial> {
  const UserSelect({
    this.id = true,
    this.email = true,
    this.role = true,
    this.tags = true,
    this.relations,
  });

  final bool id;

  final bool email;

  final bool role;

  final bool tags;

  final UserRelations? relations;

  @override
  bool get hasSelections =>
      id || email || role || tags || (relations?.hasSelections ?? false);

  @override
  void collect(
    QueryFieldsContext<User> context,
    List<SelectField> out, {
    String? path,
  }) {
    if (context is! UserFieldsContext) {
      throw ArgumentError('Expected UserFieldsContext for UserSelect');
    }
    final UserFieldsContext scoped = context;
    String? aliasFor(String column) {
      final current = path;
      if (current == null || current.isEmpty) return null;
      return '${current}_$column';
    }

    final tableAlias = scoped.currentAlias;
    if (id) {
      out.add(SelectField('id', tableAlias: tableAlias, alias: aliasFor('id')));
    }
    if (email) {
      out.add(
        SelectField('email', tableAlias: tableAlias, alias: aliasFor('email')),
      );
    }
    if (role) {
      out.add(
        SelectField('role', tableAlias: tableAlias, alias: aliasFor('role')),
      );
    }
    if (tags) {
      out.add(
        SelectField('tags', tableAlias: tableAlias, alias: aliasFor('tags')),
      );
    }
    final rels = relations;
    if (rels != null && rels.hasSelections) {
      rels.collect(scoped, out, path: path);
    }
  }

  @override
  UserPartial hydrate(Map<String, dynamic> row, {String? path}) {
    // Collection relation posts requires row aggregation
    return UserPartial(
      id: id ? readValue(row, 'id', path: path) as int : null,
      email: email ? readValue(row, 'email', path: path) as String : null,
      role: role
          ? Role.values.byName(readValue(row, 'role', path: path) as String)
          : null,
      tags: tags
          ? (decodeJsonColumn(readValue(row, 'tags', path: path)) as List)
                .cast<String>()
          : null,
      posts: null,
    );
  }

  @override
  bool get hasCollectionRelations => true;

  @override
  String? get primaryKeyColumn => 'id';

  @override
  List<UserPartial> aggregateRows(
    List<Map<String, dynamic>> rows, {
    String? path,
  }) {
    if (rows.isEmpty) return [];
    final grouped = <Object?, List<Map<String, dynamic>>>{};
    for (final row in rows) {
      final key = readValue(row, 'id', path: path);
      (grouped[key] ??= []).add(row);
    }
    return grouped.entries.map((entry) {
      final groupRows = entry.value;
      final firstRow = groupRows.first;
      final base = hydrate(firstRow, path: path);
      // Aggregate posts collection
      final postsSelect = relations?.posts;
      List<PostPartial>? postsList;
      if (postsSelect != null && postsSelect.hasSelections) {
        final relationPath = extendPath(path, 'posts');
        postsList = <PostPartial>[];
        final seenKeys = <Object?>{};
        for (final row in groupRows) {
          final itemKey = postsSelect.readValue(
            row,
            postsSelect.primaryKeyColumn ?? 'id',
            path: relationPath,
          );
          if (itemKey != null && seenKeys.add(itemKey)) {
            postsList.add(postsSelect.hydrate(row, path: relationPath));
          }
        }
      }
      return UserPartial(
        id: base.id,
        email: base.email,
        role: base.role,
        tags: base.tags,
        posts: postsList,
      );
    }).toList();
  }
}

class UserRelations {
  const UserRelations({this.posts});

  final PostSelect? posts;

  bool get hasSelections => (posts?.hasSelections ?? false);

  void collect(
    UserFieldsContext context,
    List<SelectField> out, {
    String? path,
  }) {
    final postsSelect = posts;
    if (postsSelect != null && postsSelect.hasSelections) {
      final relationPath = path == null || path.isEmpty
          ? 'posts'
          : '${path}_posts';
      final relationContext = context.posts;
      postsSelect.collect(relationContext, out, path: relationPath);
    }
  }
}

class UserPartial extends PartialEntity<User> {
  const UserPartial({this.id, this.email, this.role, this.tags, this.posts});

  final int? id;

  final String? email;

  final Role? role;

  final List<String>? tags;

  final List<PostPartial>? posts;

  @override
  Object? get primaryKeyValue {
    return id;
  }

  @override
  UserInsertDto toInsertDto() {
    final missing = <String>[];
    if (email == null) missing.add('email');
    if (role == null) missing.add('role');
    if (tags == null) missing.add('tags');
    if (missing.isNotEmpty) {
      throw StateError(
        'Cannot convert UserPartial to UserInsertDto: missing required fields: ${missing.join(', ')}',
      );
    }
    return UserInsertDto(
      email: email!,
      role: role!,
      tags: tags!,
      posts: posts?.map((p) => p.toInsertDto()).toList(),
    );
  }

  @override
  UserUpdateDto toUpdateDto() {
    return UserUpdateDto(email: email, role: role, tags: tags);
  }

  @override
  User toEntity() {
    final missing = <String>[];
    if (id == null) missing.add('id');
    if (email == null) missing.add('email');
    if (role == null) missing.add('role');
    if (tags == null) missing.add('tags');
    if (missing.isNotEmpty) {
      throw StateError(
        'Cannot convert UserPartial to User: missing required fields: ${missing.join(', ')}',
      );
    }
    return User(
      id: id!,
      email: email!,
      role: role!,
      tags: tags!,
      posts: posts?.map((p) => p.toEntity()).toList() ?? const <Post>[],
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'role': role?.name,
      'tags': tags,
      'posts': posts?.map((e) => e.toJson()).toList(),
    };
  }
}

class UserInsertDto implements InsertDto<User> {
  const UserInsertDto({
    required this.email,
    required this.role,
    required this.tags,
    this.posts,
  });

  final String email;

  final Role role;

  final List<String> tags;

  final List<PostInsertDto>? posts;

  @override
  Map<String, dynamic> toMap() {
    return {'email': email, 'role': role.name, 'tags': tags};
  }

  Map<String, dynamic> get cascades {
    return {if (posts != null) 'posts': posts};
  }

  UserInsertDto copyWith({
    String? email,
    Role? role,
    List<String>? tags,
    List<PostInsertDto>? posts,
  }) {
    return UserInsertDto(
      email: email ?? this.email,
      role: role ?? this.role,
      tags: tags ?? this.tags,
      posts: posts ?? this.posts,
    );
  }
}

class UserUpdateDto implements UpdateDto<User> {
  const UserUpdateDto({this.email, this.role, this.tags});

  final String? email;

  final Role? role;

  final List<String>? tags;

  @override
  Map<String, dynamic> toMap() {
    return {
      if (email != null) 'email': email,
      if (role != null) 'role': role?.name,
      if (tags != null) 'tags': tags,
    };
  }

  Map<String, dynamic> get cascades {
    return const {};
  }
}

class UserRepository extends EntityRepository<User, UserPartial> {
  UserRepository(EngineAdapter engine)
    : super($UserEntityDescriptor, engine, $UserEntityDescriptor.fieldsContext);
}

extension UserJson on User {
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'role': role.name,
      'tags': tags,
      'posts': posts.map((e) => e.toJson()).toList(),
    };
  }
}

/// Result DTO for the [countUsers] query.
final class CountUsersResult {
  const CountUsersResult({required this.total});

  factory CountUsersResult.fromMap(Map<String, dynamic> map) {
    return CountUsersResult(total: map['total'] as int);
  }

  final int total;
}

extension UserRepositoryExtensions
    on EntityRepository<User, PartialEntity<User>> {
  Future<User> findByEmail(String email) async {
    final rows = await engine.query(
      'SELECT * FROM users WHERE email = ? LIMIT 1',
      [email],
    );
    final entity = descriptor.fromRow(rows.first);
    return entity;
  }

  Future<CountUsersResult> countUsers() async {
    final rows = await engine.query('SELECT COUNT(*) as total FROM users', []);
    return CountUsersResult.fromMap(rows.first);
  }

  Future<List<PartialEntity<User>>> getUserEmailsAndRoles() async {
    final rows = await engine.query('SELECT email, role FROM users', []);
    final selectOpts = UserSelect();
    return rows.map((row) => selectOpts.hydrate(row)).toList();
  }

  Future<List<User>> findAllUsers() async {
    final rows = await engine.query('SELECT * FROM users', []);
    final entities = rows.map((row) => descriptor.fromRow(row)).toList();
    return entities;
  }
}

final EntityDescriptor<Post, PostPartial> $PostEntityDescriptor =
    EntityDescriptor(
      entityType: Post,
      tableName: 'posts',
      columns: [
        ColumnDescriptor(
          name: 'id',
          propertyName: 'id',
          type: ColumnType.uuid,
          nullable: false,
          unique: false,
          isPrimaryKey: true,
          autoIncrement: false,
          uuid: true,
        ),
        ColumnDescriptor(
          name: 'title',
          propertyName: 'title',
          type: ColumnType.text,
          nullable: false,
          unique: false,
          isPrimaryKey: false,
          autoIncrement: false,
          uuid: false,
        ),
        ColumnDescriptor(
          name: 'content',
          propertyName: 'content',
          type: ColumnType.text,
          nullable: false,
          unique: false,
          isPrimaryKey: false,
          autoIncrement: false,
          uuid: false,
        ),
        ColumnDescriptor(
          name: 'likes',
          propertyName: 'likes',
          type: ColumnType.integer,
          nullable: false,
          unique: false,
          isPrimaryKey: false,
          autoIncrement: false,
          uuid: false,
          defaultValue: 0,
        ),
        ColumnDescriptor(
          name: 'created_at',
          propertyName: 'createdAt',
          type: ColumnType.dateTime,
          nullable: true,
          unique: false,
          isPrimaryKey: false,
          autoIncrement: false,
          uuid: false,
        ),
        ColumnDescriptor(
          name: 'last_updated_at',
          propertyName: 'lastUpdatedAt',
          type: ColumnType.dateTime,
          nullable: true,
          unique: false,
          isPrimaryKey: false,
          autoIncrement: false,
          uuid: false,
        ),
      ],
      relations: const [
        RelationDescriptor(
          fieldName: 'user',
          type: RelationType.manyToOne,
          target: User,
          isOwningSide: true,
          fetch: RelationFetchStrategy.lazy,
          cascade: const [],
          cascadePersist: false,
          cascadeMerge: false,
          cascadeRemove: false,
          joinColumn: JoinColumnDescriptor(
            name: 'user_id',
            referencedColumnName: 'id',
            nullable: true,
            unique: false,
          ),
        ),
        RelationDescriptor(
          fieldName: 'tags',
          type: RelationType.manyToMany,
          target: Tag,
          isOwningSide: true,
          fetch: RelationFetchStrategy.lazy,
          cascade: const [RelationCascade.persist, RelationCascade.remove],
          cascadePersist: true,
          cascadeMerge: false,
          cascadeRemove: true,
          joinTable: JoinTableDescriptor(
            name: 'post_tags',
            joinColumns: [
              JoinColumnDescriptor(
                name: 'post_id',
                referencedColumnName: 'id',
                nullable: true,
                unique: false,
              ),
            ],
            inverseJoinColumns: [
              JoinColumnDescriptor(
                name: 'tag_id',
                referencedColumnName: 'id',
                nullable: true,
                unique: false,
              ),
            ],
          ),
        ),
      ],
      fromRow: (row) => Post(
        id: (row['id'] as String),
        title: (row['title'] as String),
        content: (row['content'] as String),
        likes: (row['likes'] as int),
        createdAt: row['created_at'] == null
            ? null
            : row['created_at'] is String
            ? DateTime.parse(row['created_at'].toString())
            : row['created_at'] as DateTime,
        lastUpdatedAt: row['last_updated_at'] == null
            ? null
            : (row['last_updated_at'] is String
                      ? DateTime.parse(row['last_updated_at'].toString())
                      : row['last_updated_at'] as DateTime)
                  .millisecondsSinceEpoch,
        user: null,
        tags: const <Tag>[],
      ),
      toRow: (e) => {
        'id': e.id,
        'title': e.title,
        'content': e.content,
        'likes': e.likes,
        'created_at': e.createdAt?.toIso8601String(),
        'last_updated_at': e.lastUpdatedAt == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(
                e.lastUpdatedAt as int,
              ).toIso8601String(),
        'user_id': e.user?.id,
      },
      fieldsContext: const PostFieldsContext(),
      repositoryFactory: (EngineAdapter engine) => PostRepository(engine),
      hooks: EntityHooks<Post>(
        preRemove: (e) {
          e.beforeDelete();
        },
        prePersist: (e) {
          e.createdAt = DateTime.now();
          e.lastUpdatedAt = DateTime.now().millisecondsSinceEpoch;
        },
        preUpdate: (e) {
          e.lastUpdatedAt = DateTime.now().millisecondsSinceEpoch;
        },
      ),
      defaultSelect: () => PostSelect(),
    );

class PostFieldsContext extends QueryFieldsContext<Post> {
  const PostFieldsContext([super.runtimeContext, super.alias]);

  @override
  PostFieldsContext bind(QueryRuntimeContext runtimeContext, String alias) =>
      PostFieldsContext(runtimeContext, alias);

  QueryField<String> get id => field<String>('id');

  QueryField<String> get title => field<String>('title');

  QueryField<String> get content => field<String>('content');

  QueryField<int> get likes => field<int>('likes');

  QueryField<DateTime?> get createdAt => field<DateTime?>('created_at');

  QueryField<int?> get lastUpdatedAt => field<int?>('last_updated_at');

  QueryField<int?> get userId => field<int?>('user_id');

  UserFieldsContext get user {
    final alias = ensureRelationJoin(
      relationName: 'user',
      targetTableName: $UserEntityDescriptor.qualifiedTableName,
      localColumn: 'user_id',
      foreignColumn: 'id',
      joinType: JoinType.left,
    );
    return UserFieldsContext(runtimeOrThrow, alias);
  }

  /// Join through the post_tags join table
  TagFieldsContext get tags {
    final joinTableAlias = ensureRelationJoin(
      relationName: 'tags_jt',
      targetTableName: 'post_tags',
      localColumn: 'id',
      foreignColumn: 'post_id',
      joinType: JoinType.left,
    );
    final alias = ensureRelationJoinFrom(
      fromAlias: joinTableAlias,
      relationName: 'tags',
      targetTableName: $TagEntityDescriptor.qualifiedTableName,
      localColumn: 'tag_id',
      foreignColumn: 'id',
      joinType: JoinType.left,
    );
    return TagFieldsContext(runtimeOrThrow, alias);
  }
}

class PostQuery extends QueryBuilder<Post> {
  const PostQuery(this._builder);

  final WhereExpression Function(PostFieldsContext) _builder;

  @override
  WhereExpression build(QueryFieldsContext<Post> context) {
    if (context is! PostFieldsContext) {
      throw ArgumentError('Expected PostFieldsContext for PostQuery');
    }
    return _builder(context);
  }
}

class PostSelect extends SelectOptions<Post, PostPartial> {
  const PostSelect({
    this.id = true,
    this.title = true,
    this.content = true,
    this.likes = true,
    this.createdAt = true,
    this.lastUpdatedAt = true,
    this.userId = true,
    this.relations,
  });

  final bool id;

  final bool title;

  final bool content;

  final bool likes;

  final bool createdAt;

  final bool lastUpdatedAt;

  final bool userId;

  final PostRelations? relations;

  @override
  bool get hasSelections =>
      id ||
      title ||
      content ||
      likes ||
      createdAt ||
      lastUpdatedAt ||
      userId ||
      (relations?.hasSelections ?? false);

  @override
  void collect(
    QueryFieldsContext<Post> context,
    List<SelectField> out, {
    String? path,
  }) {
    if (context is! PostFieldsContext) {
      throw ArgumentError('Expected PostFieldsContext for PostSelect');
    }
    final PostFieldsContext scoped = context;
    String? aliasFor(String column) {
      final current = path;
      if (current == null || current.isEmpty) return null;
      return '${current}_$column';
    }

    final tableAlias = scoped.currentAlias;
    if (id) {
      out.add(SelectField('id', tableAlias: tableAlias, alias: aliasFor('id')));
    }
    if (title) {
      out.add(
        SelectField('title', tableAlias: tableAlias, alias: aliasFor('title')),
      );
    }
    if (content) {
      out.add(
        SelectField(
          'content',
          tableAlias: tableAlias,
          alias: aliasFor('content'),
        ),
      );
    }
    if (likes) {
      out.add(
        SelectField('likes', tableAlias: tableAlias, alias: aliasFor('likes')),
      );
    }
    if (createdAt) {
      out.add(
        SelectField(
          'created_at',
          tableAlias: tableAlias,
          alias: aliasFor('created_at'),
        ),
      );
    }
    if (lastUpdatedAt) {
      out.add(
        SelectField(
          'last_updated_at',
          tableAlias: tableAlias,
          alias: aliasFor('last_updated_at'),
        ),
      );
    }
    if (userId) {
      out.add(
        SelectField(
          'user_id',
          tableAlias: tableAlias,
          alias: aliasFor('user_id'),
        ),
      );
    }
    final rels = relations;
    if (rels != null && rels.hasSelections) {
      rels.collect(scoped, out, path: path);
    }
  }

  @override
  PostPartial hydrate(Map<String, dynamic> row, {String? path}) {
    UserPartial? userPartial;
    final userSelect = relations?.user;
    if (userSelect != null && userSelect.hasSelections) {
      userPartial = userSelect.hydrate(row, path: extendPath(path, 'user'));
    }
    return PostPartial(
      id: id ? readValue(row, 'id', path: path) as String : null,
      title: title ? readValue(row, 'title', path: path) as String : null,
      content: content ? readValue(row, 'content', path: path) as String : null,
      likes: likes ? readValue(row, 'likes', path: path) as int : null,
      createdAt: createdAt
          ? readValue(row, 'created_at', path: path) == null
                ? null
                : (readValue(row, 'created_at', path: path) is String
                      ? DateTime.parse(
                          readValue(row, 'created_at', path: path) as String,
                        )
                      : readValue(row, 'created_at', path: path) as DateTime)
          : null,
      lastUpdatedAt: lastUpdatedAt
          ? readValue(row, 'last_updated_at', path: path) == null
                ? null
                : (readValue(row, 'last_updated_at', path: path) is String
                          ? DateTime.parse(
                              readValue(row, 'last_updated_at', path: path)
                                  as String,
                            )
                          : readValue(row, 'last_updated_at', path: path)
                                as DateTime)
                      .millisecondsSinceEpoch
          : null,
      userId: userId ? readValue(row, 'user_id', path: path) as int? : null,
      user: userPartial,
    );
  }

  @override
  bool get hasCollectionRelations => false;

  @override
  String? get primaryKeyColumn => 'id';
}

class PostRelations {
  const PostRelations({this.user, this.tags});

  final UserSelect? user;

  final TagSelect? tags;

  bool get hasSelections =>
      (user?.hasSelections ?? false) || (tags?.hasSelections ?? false);

  void collect(
    PostFieldsContext context,
    List<SelectField> out, {
    String? path,
  }) {
    final userSelect = user;
    if (userSelect != null && userSelect.hasSelections) {
      final relationPath = path == null || path.isEmpty
          ? 'user'
          : '${path}_user';
      final relationContext = context.user;
      userSelect.collect(relationContext, out, path: relationPath);
    }
    final tagsSelect = tags;
    if (tagsSelect != null && tagsSelect.hasSelections) {
      final relationPath = path == null || path.isEmpty
          ? 'tags'
          : '${path}_tags';
      final relationContext = context.tags;
      tagsSelect.collect(relationContext, out, path: relationPath);
    }
  }
}

class PostPartial extends PartialEntity<Post> {
  const PostPartial({
    this.id,
    this.title,
    this.content,
    this.likes,
    this.createdAt,
    this.lastUpdatedAt,
    this.userId,
    this.user,
    this.tags,
  });

  final String? id;

  final String? title;

  final String? content;

  final int? likes;

  final DateTime? createdAt;

  final int? lastUpdatedAt;

  final int? userId;

  final UserPartial? user;

  final List<TagPartial>? tags;

  @override
  Object? get primaryKeyValue {
    return id;
  }

  @override
  PostInsertDto toInsertDto() {
    final missing = <String>[];
    if (title == null) missing.add('title');
    if (content == null) missing.add('content');
    if (missing.isNotEmpty) {
      throw StateError(
        'Cannot convert PostPartial to PostInsertDto: missing required fields: ${missing.join(', ')}',
      );
    }
    return PostInsertDto(
      title: title!,
      content: content!,
      likes: likes ?? 0,
      createdAt: createdAt,
      lastUpdatedAt: lastUpdatedAt,
      userId: userId,
      tags: tags?.map((p) => p.toInsertDto()).toList(),
    );
  }

  @override
  PostUpdateDto toUpdateDto() {
    return PostUpdateDto(
      title: title,
      content: content,
      likes: likes,
      createdAt: createdAt,
      lastUpdatedAt: lastUpdatedAt,
      userId: userId,
    );
  }

  @override
  Post toEntity() {
    final missing = <String>[];
    if (id == null) missing.add('id');
    if (title == null) missing.add('title');
    if (content == null) missing.add('content');
    if (likes == null) missing.add('likes');
    if (missing.isNotEmpty) {
      throw StateError(
        'Cannot convert PostPartial to Post: missing required fields: ${missing.join(', ')}',
      );
    }
    return Post(
      id: id!,
      title: title!,
      content: content!,
      likes: likes!,
      createdAt: createdAt,
      lastUpdatedAt: lastUpdatedAt,
      user: user?.toEntity(),
      tags: tags?.map((p) => p.toEntity()).toList() ?? const <Tag>[],
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'likes': likes,
      'createdAt': createdAt?.toIso8601String(),
      'lastUpdatedAt': lastUpdatedAt,
      'user': user?.toJson(),
      'tags': tags?.map((e) => e.toJson()).toList(),
      'userId': userId,
    };
  }
}

class PostInsertDto implements InsertDto<Post> {
  const PostInsertDto({
    required this.title,
    required this.content,
    this.likes = 0,
    this.createdAt,
    this.lastUpdatedAt,
    this.userId,
    this.tags,
  });

  final String title;

  final String content;

  final int likes;

  final DateTime? createdAt;

  final int? lastUpdatedAt;

  final int? userId;

  final List<TagInsertDto>? tags;

  @override
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'content': content,
      'likes': likes,
      'created_at': DateTime.now().toIso8601String(),
      'last_updated_at': DateTime.fromMillisecondsSinceEpoch(
        DateTime.now().millisecondsSinceEpoch,
      ).toIso8601String(),
      if (userId != null) 'user_id': userId,
    };
  }

  Map<String, dynamic> get cascades {
    return {if (tags != null) 'tags': tags};
  }

  PostInsertDto copyWith({
    String? title,
    String? content,
    int? likes,
    DateTime? createdAt,
    int? lastUpdatedAt,
    int? userId,
    List<TagInsertDto>? tags,
  }) {
    return PostInsertDto(
      title: title ?? this.title,
      content: content ?? this.content,
      likes: likes ?? this.likes,
      createdAt: createdAt ?? this.createdAt,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
      userId: userId ?? this.userId,
      tags: tags ?? this.tags,
    );
  }
}

class PostUpdateDto implements UpdateDto<Post> {
  const PostUpdateDto({
    this.title,
    this.content,
    this.likes,
    this.createdAt,
    this.lastUpdatedAt,
    this.userId,
  });

  final String? title;

  final String? content;

  final int? likes;

  final DateTime? createdAt;

  final int? lastUpdatedAt;

  final int? userId;

  @override
  Map<String, dynamic> toMap() {
    return {
      if (title != null) 'title': title,
      if (content != null) 'content': content,
      if (likes != null) 'likes': likes,
      if (createdAt != null)
        'created_at': createdAt is DateTime
            ? (createdAt as DateTime).toIso8601String()
            : createdAt?.toString(),
      'last_updated_at': DateTime.fromMillisecondsSinceEpoch(
        DateTime.now().millisecondsSinceEpoch,
      ).toIso8601String(),
      if (userId != null) 'user_id': userId,
    };
  }

  Map<String, dynamic> get cascades {
    return const {};
  }
}

class PostRepository extends EntityRepository<Post, PostPartial> {
  PostRepository(EngineAdapter engine)
    : super($PostEntityDescriptor, engine, $PostEntityDescriptor.fieldsContext);
}

extension PostJson on Post {
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'likes': likes,
      'createdAt': createdAt?.toIso8601String(),
      'lastUpdatedAt': lastUpdatedAt,
      'user': user?.toJson(),
      'tags': tags.map((e) => e.toJson()).toList(),
    };
  }
}

extension PostRepositoryExtensions
    on EntityRepository<Post, PartialEntity<Post>> {}

final EntityDescriptor<Tag, TagPartial> $TagEntityDescriptor = EntityDescriptor(
  entityType: Tag,
  tableName: 'tag',
  columns: [
    ColumnDescriptor(
      name: 'id',
      propertyName: 'id',
      type: ColumnType.integer,
      nullable: false,
      unique: false,
      isPrimaryKey: true,
      autoIncrement: true,
      uuid: false,
    ),
    ColumnDescriptor(
      name: 'name',
      propertyName: 'name',
      type: ColumnType.text,
      nullable: false,
      unique: false,
      isPrimaryKey: false,
      autoIncrement: false,
      uuid: false,
    ),
  ],
  relations: const [
    RelationDescriptor(
      fieldName: 'posts',
      type: RelationType.manyToMany,
      target: Post,
      isOwningSide: false,
      mappedBy: 'tags',
      fetch: RelationFetchStrategy.lazy,
      cascade: const [],
      cascadePersist: false,
      cascadeMerge: false,
      cascadeRemove: false,
    ),
  ],
  fromRow: (row) => Tag(
    id: (row['id'] as int),
    name: (row['name'] as String),
    posts: const <Post>[],
  ),
  toRow: (e) => {'id': e.id, 'name': e.name},
  fieldsContext: const TagFieldsContext(),
  repositoryFactory: (EngineAdapter engine) => TagRepository(engine),
  defaultSelect: () => TagSelect(),
);

class TagFieldsContext extends QueryFieldsContext<Tag> {
  const TagFieldsContext([super.runtimeContext, super.alias]);

  @override
  TagFieldsContext bind(QueryRuntimeContext runtimeContext, String alias) =>
      TagFieldsContext(runtimeContext, alias);

  QueryField<int> get id => field<int>('id');

  QueryField<String> get name => field<String>('name');

  /// Find the owning relation on the target entity to get join column info
  PostFieldsContext get posts {
    final targetRelation = $PostEntityDescriptor.relations.firstWhere(
      (r) => r.fieldName == 'tags',
    );
    final joinColumn = targetRelation.joinColumn!;
    final alias = ensureRelationJoin(
      relationName: 'posts',
      targetTableName: $PostEntityDescriptor.qualifiedTableName,
      localColumn: joinColumn.referencedColumnName,
      foreignColumn: joinColumn.name,
      joinType: JoinType.left,
    );
    return PostFieldsContext(runtimeOrThrow, alias);
  }
}

class TagQuery extends QueryBuilder<Tag> {
  const TagQuery(this._builder);

  final WhereExpression Function(TagFieldsContext) _builder;

  @override
  WhereExpression build(QueryFieldsContext<Tag> context) {
    if (context is! TagFieldsContext) {
      throw ArgumentError('Expected TagFieldsContext for TagQuery');
    }
    return _builder(context);
  }
}

class TagSelect extends SelectOptions<Tag, TagPartial> {
  const TagSelect({this.id = true, this.name = true, this.relations});

  final bool id;

  final bool name;

  final TagRelations? relations;

  @override
  bool get hasSelections => id || name || (relations?.hasSelections ?? false);

  @override
  void collect(
    QueryFieldsContext<Tag> context,
    List<SelectField> out, {
    String? path,
  }) {
    if (context is! TagFieldsContext) {
      throw ArgumentError('Expected TagFieldsContext for TagSelect');
    }
    final TagFieldsContext scoped = context;
    String? aliasFor(String column) {
      final current = path;
      if (current == null || current.isEmpty) return null;
      return '${current}_$column';
    }

    final tableAlias = scoped.currentAlias;
    if (id) {
      out.add(SelectField('id', tableAlias: tableAlias, alias: aliasFor('id')));
    }
    if (name) {
      out.add(
        SelectField('name', tableAlias: tableAlias, alias: aliasFor('name')),
      );
    }
    final rels = relations;
    if (rels != null && rels.hasSelections) {
      rels.collect(scoped, out, path: path);
    }
  }

  @override
  TagPartial hydrate(Map<String, dynamic> row, {String? path}) {
    // Collection relation posts requires row aggregation
    return TagPartial(
      id: id ? readValue(row, 'id', path: path) as int : null,
      name: name ? readValue(row, 'name', path: path) as String : null,
      posts: null,
    );
  }

  @override
  bool get hasCollectionRelations => true;

  @override
  String? get primaryKeyColumn => 'id';

  @override
  List<TagPartial> aggregateRows(
    List<Map<String, dynamic>> rows, {
    String? path,
  }) {
    if (rows.isEmpty) return [];
    final grouped = <Object?, List<Map<String, dynamic>>>{};
    for (final row in rows) {
      final key = readValue(row, 'id', path: path);
      (grouped[key] ??= []).add(row);
    }
    return grouped.entries.map((entry) {
      final groupRows = entry.value;
      final firstRow = groupRows.first;
      final base = hydrate(firstRow, path: path);
      // Aggregate posts collection
      final postsSelect = relations?.posts;
      List<PostPartial>? postsList;
      if (postsSelect != null && postsSelect.hasSelections) {
        final relationPath = extendPath(path, 'posts');
        postsList = <PostPartial>[];
        final seenKeys = <Object?>{};
        for (final row in groupRows) {
          final itemKey = postsSelect.readValue(
            row,
            postsSelect.primaryKeyColumn ?? 'id',
            path: relationPath,
          );
          if (itemKey != null && seenKeys.add(itemKey)) {
            postsList.add(postsSelect.hydrate(row, path: relationPath));
          }
        }
      }
      return TagPartial(id: base.id, name: base.name, posts: postsList);
    }).toList();
  }
}

class TagRelations {
  const TagRelations({this.posts});

  final PostSelect? posts;

  bool get hasSelections => (posts?.hasSelections ?? false);

  void collect(
    TagFieldsContext context,
    List<SelectField> out, {
    String? path,
  }) {
    final postsSelect = posts;
    if (postsSelect != null && postsSelect.hasSelections) {
      final relationPath = path == null || path.isEmpty
          ? 'posts'
          : '${path}_posts';
      final relationContext = context.posts;
      postsSelect.collect(relationContext, out, path: relationPath);
    }
  }
}

class TagPartial extends PartialEntity<Tag> {
  const TagPartial({this.id, this.name, this.posts});

  final int? id;

  final String? name;

  final List<PostPartial>? posts;

  @override
  Object? get primaryKeyValue {
    return id;
  }

  @override
  TagInsertDto toInsertDto() {
    final missing = <String>[];
    if (name == null) missing.add('name');
    if (missing.isNotEmpty) {
      throw StateError(
        'Cannot convert TagPartial to TagInsertDto: missing required fields: ${missing.join(', ')}',
      );
    }
    return TagInsertDto(name: name!);
  }

  @override
  TagUpdateDto toUpdateDto() {
    return TagUpdateDto(name: name);
  }

  @override
  Tag toEntity() {
    final missing = <String>[];
    if (id == null) missing.add('id');
    if (name == null) missing.add('name');
    if (missing.isNotEmpty) {
      throw StateError(
        'Cannot convert TagPartial to Tag: missing required fields: ${missing.join(', ')}',
      );
    }
    return Tag(
      id: id!,
      name: name!,
      posts: posts?.map((p) => p.toEntity()).toList() ?? const <Post>[],
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'posts': posts?.map((e) => e.toJson()).toList(),
    };
  }
}

class TagInsertDto implements InsertDto<Tag> {
  const TagInsertDto({required this.name});

  final String name;

  @override
  Map<String, dynamic> toMap() {
    return {'name': name};
  }

  Map<String, dynamic> get cascades {
    return const {};
  }

  TagInsertDto copyWith({String? name}) {
    return TagInsertDto(name: name ?? this.name);
  }
}

class TagUpdateDto implements UpdateDto<Tag> {
  const TagUpdateDto({this.name});

  final String? name;

  @override
  Map<String, dynamic> toMap() {
    return {if (name != null) 'name': name};
  }

  Map<String, dynamic> get cascades {
    return const {};
  }
}

class TagRepository extends EntityRepository<Tag, TagPartial> {
  TagRepository(EngineAdapter engine)
    : super($TagEntityDescriptor, engine, $TagEntityDescriptor.fieldsContext);
}

extension TagJson on Tag {
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'posts': posts.map((e) => e.toJson()).toList(),
    };
  }
}

extension TagRepositoryExtensions
    on EntityRepository<Tag, PartialEntity<Tag>> {}
