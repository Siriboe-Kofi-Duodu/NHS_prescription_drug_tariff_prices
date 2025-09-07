-- schema.sql
-- Creating tables for the NHS drug prescriptions database

PRAGMA foreign_keys = OFF;

CREATE TABLE BNF_Chapter (
    BNF_Chapter_Code TEXT PRIMARY KEY,
    BNF_Chapter_Name TEXT NOT NULL
);

CREATE TABLE BNF_Section (
    BNF_Section_Code TEXT PRIMARY KEY,
    BNF_Section_Name TEXT NOT NULL,
    BNF_Chapter_Code TEXT,
    FOREIGN KEY (BNF_Chapter_Code) REFERENCES BNF_Chapter(BNF_Chapter_Code)
);

CREATE TABLE BNF_Paragraph (
    BNF_Paragraph_Code TEXT PRIMARY KEY,
    BNF_Paragraph_Name TEXT NOT NULL,
    BNF_Section_Code TEXT,
    FOREIGN KEY (BNF_Section_Code) REFERENCES BNF_Section(BNF_Section_Code)
);

CREATE TABLE Chemical_Substance (
    BNF_Chemical_Substance_Code TEXT PRIMARY KEY,
    BNF_Chemical_Substance TEXT NOT NULL,
    BNF_Paragraph_Code TEXT,
    FOREIGN KEY (BNF_Paragraph_Code) REFERENCES BNF_Paragraph(BNF_Paragraph_Code)
);

CREATE TABLE Region (
    Region_Code TEXT PRIMARY KEY,
    Region_Name TEXT NOT NULL
);

CREATE TABLE ICB (
    ICB_Code TEXT PRIMARY KEY,
    ICB_Name TEXT NOT NULL,
    Region_Code TEXT,
    FOREIGN KEY (Region_Code) REFERENCES Region(Region_Code)
);

CREATE TABLE VTM (
    VTMID TEXT PRIMARY KEY,
    VTM_Name TEXT,
    VMP_Code TEXT
);

CREATE TABLE VMP (
    VMP_Code TEXT PRIMARY KEY,
    BNF_Code TEXT,
    BNF_Name TEXT,
    VTMID TEXT,
    FOREIGN KEY (VTMID) REFERENCES VTM(VTMID)
);

CREATE TABLE VMPP (
    VMPP_Code TEXT PRIMARY KEY,
    VMP_Code TEXT,
    DM_D_Product_and_Pack_Description TEXT,
    Pack TEXT,
    Unit_of_Measure TEXT,
    Strength TEXT,
    FOREIGN KEY (VMP_Code) REFERENCES VMP(VMP_Code)
);

CREATE TABLE AMP (
    AMP_Code TEXT PRIMARY KEY,
    BNF_Code TEXT,
    BNF_Name TEXT,
    VTMID TEXT,
    FOREIGN KEY (VTMID) REFERENCES VTM(VTMID)
);

CREATE TABLE AMPP (
    AMPP_Code TEXT PRIMARY KEY,
    AMP_Code TEXT,
    DM_D_Product_and_Pack_Description TEXT,
    Pack TEXT,
    Unit_of_Measure TEXT,
    Strength TEXT,
    BNF_Code TEXT,
    FOREIGN KEY (AMP_Code) REFERENCES AMP(AMP_Code)
);

CREATE TABLE BNF_Presentation (
    BNF_ID INTEGER PRIMARY KEY AUTOINCREMENT,
    BNF_Presentation_Code TEXT NOT NULL,
    Year_Month TEXT NOT NULL,
    BNF_Presentation_Name TEXT,
    SNOMED_Code TEXT,
    Generic_BNF_Equivalent_Code TEXT,
    Generic_BNF_Equivalent_Name TEXT,
    Dispenser_Account_Type TEXT,
    Prep_Class TEXT,
    Prescribed_Prep_Class TEXT,
    Unit_of_Measure TEXT,
    Supplier_Name TEXT,
    BNF_Chemical_Substance_Code TEXT,
    Pharmacy_Advanced_Service TEXT,
    Items INTEGER,
    Total_Quantity REAL,
    NIC REAL,
    Prescription_Type TEXT,
    Drug_Category TEXT,
    Reimbursement_Prices REAL,
    FOREIGN KEY (BNF_Chemical_Substance_Code) REFERENCES Chemical_Substance(BNF_Chemical_Substance_Code)
);

CREATE TABLE Part_VIIIA_Tariff (
    Year_Month TEXT,
    Medicine TEXT,
    Pack_Size TEXT,
    VMP_Snomed_Code TEXT,
    VMPP_Snomed_Code TEXT,
    Drug_Tariff_Category TEXT
    Price REAL,
    CP REAL,
    Reimbursement_Price REAL,
    PRIMARY KEY (Year_Month, VMPP_Snomed_Code)
);

CREATE TABLE specials_tariff (
    VMP_Snomed_Code TEXT,
    VMPP_Snomed_Code TEXT,
    Medicine TEXT,
    Pack_Size TEXT,
    Unit TEXT,
    Formulations TEXT,
    Special_Container TEXT,
    Price REAL,
    Quarter TEXT,
    Drug_Category TEXT,
    BNF_Code TEXT,
    PRIMARY KEY (Quarter, VMPP_Snomed_Code,Formulations)
);

CREATE TABLE Part_IX (
    Supplier_Name TEXT,
    VMP_Name TEXT,
    AMP_Name TEXT,
    QTY REAL,
    UOM_QTY TEXT,
    Price REAL,
    Product_Snomed_Code TEXT,
    Pack_Snomed_Code TEXT,
    GTIN TEXT,
    Supplier_Snomed_Code TEXT,
    BNF TEXT,
    Year_month TEXT,
    Drug_Category TEXT,
    PRIMARY KEY (Year_Month, Product_Snomed_Code)
);

PRAGMA foreign_keys = ON;
