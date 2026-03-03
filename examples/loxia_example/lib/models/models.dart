
import 'package:loxia/loxia.dart';

part 'models.g.dart';

enum Role { admin, user, guest }

@EntityMeta(
  table: 'users',
  queries: [
    // Full entity return (SELECT *) with LIMIT 1 -> single User
    Query(
      name: 'findByEmail',
      sql: 'SELECT * FROM users WHERE email = @email LIMIT 1',
    ),
    // DTO with aggregate (no GROUP BY) -> single CountUsersResult
    Query(name: 'countUsers', sql: 'SELECT COUNT(*) as total FROM users'),
    // Partial entity - specific columns subset -> List<PartialEntity>
    Query(name: 'getUserEmailsAndRoles', sql: 'SELECT email, role FROM users'),
    // Full entity return without LIMIT -> List<User>
    Query(name: 'findAllUsers', sql: 'SELECT * FROM users'),
  ],
)
class User extends Entity {
  @PrimaryKey(autoIncrement: true)
  final int id;

  @Column()
  final String email;

  @OneToMany(on: Post, mappedBy: 'user', cascade: [RelationCascade.persist])
  final List<Post> posts;

  @Column(type: ColumnType.text)
  final Role role;

  @Column(defaultValue: <String>[])
  final List<String> tags;

  User({
    required this.id,
    required this.email,
    this.posts = const [],
    this.role = Role.user,
    this.tags = const [],
  });

  static EntityDescriptor<User, UserPartial> get entity =>
      $UserEntityDescriptor;
}

@EntityMeta(table: 'posts')
class Post extends Entity {
  @PrimaryKey(uuid: true)
  final String id;

  @Column()
  final String title;

  @Column()
  final String content;

  @Column(defaultValue: 0)
  final int likes;

  @CreatedAt()
  DateTime? createdAt;

  @UpdatedAt()
  int? lastUpdatedAt;

  @ManyToOne(on: User)
  final User? user;

  @ManyToMany(
    on: Tag,
    cascade: [RelationCascade.persist, RelationCascade.remove],
  )
  @JoinTable(
    name: 'post_tags',
    joinColumns: [JoinColumn(name: 'post_id', referencedColumnName: 'id')],
    inverseJoinColumns: [
      JoinColumn(name: 'tag_id', referencedColumnName: 'id'),
    ],
  )
  final List<Tag> tags;

  Post({
    required this.id,
    required this.title,
    this.createdAt,
    this.lastUpdatedAt,
    required this.content,
    required this.likes,
    this.user,
    this.tags = const [],
  });

  static EntityDescriptor<Post, PostPartial> get entity =>
      $PostEntityDescriptor;

  @PreRemove()
  void beforeDelete() {
    print('About to delete Post with id=$id');
  }
}

@EntityMeta()
class Tag extends Entity {
  @PrimaryKey(autoIncrement: true)
  final int id;

  @Column()
  final String name;

  @ManyToMany(on: Post, mappedBy: 'tags')
  final List<Post> posts;

  Tag({required this.id, required this.name, this.posts = const []});

  static EntityDescriptor<Tag, TagPartial> get entity => $TagEntityDescriptor;
}