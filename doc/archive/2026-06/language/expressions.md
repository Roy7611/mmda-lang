# 表达式与高级语法

> Phase 2 完整实现；Phase 1 校验器可仅支持约束子集。

## 1. 数组与切片

```sql
var arr int[];
declare b int[];

var i int32[] = {0, 1, 2};
var r = range(30);
var s = r.slice(0, 10);
var s1 = r[2..];     // r[..3], r[1..10]
var a = [0..20];
```

## 2. Record 与 Tuple

记录和元组对应数据库一行，与 `struct` 同义。不需要 `class`。

```sql
var t (value int, name string) = (1, "OK");
```

## 3. Map

`Map<K,V>` 视为 `record<K,V>`；第一个元素默认为 key。

## 4. Lambda 与箭头

| 符号 | 用途 |
|------|------|
| `=>` | Lambda、映射、switch 臂 |
| `->` | **仅**状态转移 |

## 5. Switch 表达式（C# 风格）

```csharp
var s = expr switch {
    is string => 'a string',
    is int i when i > 0 => 'great',
    is Point p when p.x >= 0 && p.y >= 0 => 'positive position',
    _ => 'default'
};
```

## 6. 类型判断与转换

```dart
var b = a is Number n;
var c = a as Point?;    // 声明中的 as 是别名；此处为转换
```

## 7. 引用传递

用 `&` 表示引用传递，避免 `*` 传参歧义。

## 8. 注释与文档

| 形式 | 用途 |
|------|------|
| `///` | 文档注释（Markdown） |
| `//` | 行注释 |
| `/* */` | 行内说明 |

文档区节用 `@remarks`、`@param` 等注解风格（简洁，非 XML）。

引用：`[title](url)`、`[funcName]`。

## 9. 约束表达式（# 前缀）

```sql
#ge(0)
#(d{11})
#(name@host.com)
#future
```

校验器按内置规则库解析；自定义规则在 Profile 扩展。

## 10. 相关

- [types.md](types.md)
- [records.md](records.md)
