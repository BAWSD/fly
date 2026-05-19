import pymysql

conn = pymysql.connect(host='localhost', port=3306, user='root', password='123456')
cursor = conn.cursor()

# 检查已存在的数据库
cursor.execute("SELECT SCHEMA_NAME FROM information_schema.SCHEMATA WHERE SCHEMA_NAME IN ('flight_info','flight_status','airport_map','flight_data')")
existed = [row[0] for row in cursor.fetchall()]
print(f'已存在的数据库: {existed}')

# 确保4个数据库都存在
dbs = ['flight_info', 'flight_status', 'airport_map', 'flight_data']
for db in dbs:
    if db not in existed:
        cursor.execute(f"CREATE DATABASE IF NOT EXISTS {db} DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci")
        print(f'已创建数据库: {db}')

# 检查各数据库中的表
cursor.execute("SELECT TABLE_SCHEMA, TABLE_NAME FROM information_schema.TABLES WHERE TABLE_SCHEMA IN ('flight_info','flight_status','airport_map','flight_data')")
tables = cursor.fetchall()
print(f'\n各数据库中的表:')
if tables:
    for schema, table in tables:
        print(f'  {schema}.{table}')
else:
    print('  暂无表')

# 查看各表中的数据量
for db in dbs:
    cursor.execute(f"SELECT TABLE_NAME, TABLE_ROWS FROM information_schema.TABLES WHERE TABLE_SCHEMA='{db}'")
    rows = cursor.fetchall()
    if rows:
        print(f'\n{db} 数据量统计:')
        for table_name, table_rows in rows:
            print(f'  {table_name}: {table_rows} 行')
            # 显示前3条数据
            try:
                cursor.execute(f"SELECT * FROM {db}.{table_name} LIMIT 3")
                records = cursor.fetchall()
                if records:
                    col_names = [desc[0] for desc in cursor.description]
                    print(f'    列: {col_names}')
                    for rec in records:
                        print(f'    数据: {rec}')
            except Exception as e:
                print(f'    查询失败: {e}')

cursor.close()
conn.close()
print('\n数据库检查完成！')
