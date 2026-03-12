import random
import time

FILENAME = "RAW_TRX_DATA.txt"
TOTAL_RECORDS = 10000
INST_CODES = ["B001", "B002", "B003", "B004", "B005", "B006", "B007", "B008", "B009", "B010"]

def generate_dummy_data():
    start_time = time.time()
    total_amt = 0
    biz_date = "20260306"
    
    with open(FILENAME, 'w', encoding='ascii') as f:
        # 1. Header Record
        f.write(f"H {biz_date}\n")

        # 2. Data Records
        for seq in range(1, TOTAL_RECORDS + 1):
            rec_type = "D"
            trx_date = "20260306"
            trx_seq = f"{seq:010d}"
            inst_cd = random.choice(INST_CODES)
            acc_no = f"{random.randint(1, 999999):015d}"
            trx_type_cd = random.choice(["I", "O"])
            amt_val = random.randint(1000, 5000000)
            trx_amt = f"{amt_val:012d}"
            
            if trx_type_cd == "I":
                total_amt += amt_val
            
            record = f"{rec_type} {trx_date} {trx_seq} {inst_cd} {acc_no} {trx_type_cd} {trx_amt}\n"
            f.write(record)
            
            if seq % 2000 == 0:
                print(f"{seq:,} 건 생성 중...")

        # 3. Trailer Record
        f.write(f"T {biz_date} {TOTAL_RECORDS:010d} {total_amt:012d}\n")

    print("-" * 40)
    print(f"✅ 생성 완료: {FILENAME}")
    print(f"📊 총 건수: {TOTAL_RECORDS}건 / 입금 합계: {total_amt:,}원")

if __name__ == "__main__":
    generate_dummy_data()