import pymysql

conn = pymysql.connect(host='localhost', port=3306, user='root', password='CYN1027nn')
cursor = conn.cursor()

# 读取建表SQL
with open('flight-tracking-platform/deploy/mysql-redis/mysql/init/02-init-tables.sql', 'r', encoding='utf-8') as f:
    sql_content = f.read()

# 按分号分割，逐句执行
statements = sql_content.split(';')
success = 0
failed = 0
for stmt in statements:
    stmt = stmt.strip()
    if stmt and not stmt.startswith('USE '):
        try:
            cursor.execute(stmt)
            conn.commit()
            success += 1
            # 找出表名
            if 'CREATE TABLE' in stmt.upper():
                import re
                match = re.search(r'CREATE TABLE.*?`?(\w+)`?\s*\(', stmt, re.IGNORECASE)
                if match:
                    print(f'  创建表: {match.group(1)}')
        except Exception as e:
            if "already exists" in str(e).lower() or "duplicate" in str(e).lower():
                print(f'  表已存在: {e}')
            else:
                failed += 1

print(f'建表完成: 成功 {success} 条, 失败 {failed} 条')

# 确认表
cursor.execute("SELECT TABLE_SCHEMA, TABLE_NAME FROM information_schema.TABLES WHERE TABLE_SCHEMA IN ('flight_info','flight_status','airport_map','flight_data')")
tables = cursor.fetchall()
print(f'\n当前数据库表:')
for schema, table in tables:
    print(f'  {schema}.{table}')

cursor.close()
conn.close()
