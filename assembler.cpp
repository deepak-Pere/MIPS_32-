# include<iostream>
# include<fstream>
# include<sstream>
# include<unordered_map>
# include<iomanip>
# include<vector>

using namespace std;


const int ADD = 0b000000;
const int SUB = 0b000001;
const int AND = 0b000010;
const int OR  = 0b000011;
const int SLT = 0b000100;
const int MUL = 0b000101;
const int HLT = 0b111111;

const int LW  = 0b001000;
const int SW  = 0b001001;

const int ADDI = 0b001010;
const int SUBI = 0b001011;
const int SLTI = 0b001100;

const int BNEQZ = 0b001101;
const int BEQZ  = 0b001110;
const int JUMP  = 0b001111;
const int JAL   = 0b010000;
const int JR    = 0b010001;


//Mapping 
// We can also define as const int R1 = 1(with MUltiplexer). but it 
// give more flexibility

unordered_map<string,int> Reg = {
    {"R0", 0},{"R1", 1},{"R2", 2},{"R3", 3},
    {"R4", 4},{"R5", 5},{"R6", 6},{"R7", 7},
    {"R8", 8},{"R9", 9},{"R10", 10},{"R11", 11},
    {"R12", 12},{"R13", 13},{"R14", 14},{"R15", 15},
    {"R16", 16},{"R17", 17},{"R18", 18},{"R19", 19},
    {"R20", 20},{"R21", 21},{"R22", 22},{"R23", 23},
    {"R24", 24},{"R25", 25},{"R26", 26},{"R27", 27},
    {"R28", 28},{"R29", 29},{"R30", 30},{"R31", 31}
};

unordered_map<string,int> Label_Add;
vector<string> instruction;        //instruction

// Remove extra space 
const size_t not_found = std :: string :: npos;   //NPOS = not_found
string trim(const string &s){

    size_t start = s.find_first_not_of(" t\r\n");
    size_t end   = s.find_last_not_of(" t\r\n");

    return (start == not_found) ? "" : s.substr(start,end - start + 1);

}

//detecting label,loop
void detect(ifstream &infile)
{
    string line;
    int address = 0;


    while (getline(infile,line))
    {
        /* code */
        line = trim(line);
        if(line.empty() || line[0] == '#' || line.substr(0,2) == "//") continue;

        size_t colon = line.find(':');
        if(colon != not_found){
            string Label = trim(line.substr(0,colon));
            Label_Add[Label] = address;
            
        }

        if(!line.empty())
        {
            instruction.push_back(line);
            address++;
        }
    }

    infile.clear();   //
    infile.seekg(0);
    
}



// Assembler 

uint32_t assembleInstruction(const string &line, int curr) {

    string linefixed = line; 
    size_t colon = line.find(':');
    if(colon != not_found){
        linefixed = trim(line.substr(colon + 1));
    }


    stringstream ss(linefixed);
    string opcodeStr ;
    ss >> opcodeStr ;   //This means
    uint32_t result = 0;

    //convert to uppercase
    for(char &c : opcodeStr ) c = toupper(c);

    if(opcodeStr  == "ADD" || opcodeStr  == "SUB" || opcodeStr  == "AND" || opcodeStr  == "OR" || opcodeStr  == "SLT" || opcodeStr  == "MUL")
    {
        string rd,rs,rt;
        ss >> rd >> rs >> rt;
        rd = trim(rd);  rs = trim(rs);  rt = trim(rt);
        rd.pop_back(); rs.pop_back();  //remove commas

        int rdNum = Reg[rd];
        int rsNum = Reg[rs];
        int rtNum = Reg[rt];

        int opcode;
        if(opcodeStr == "ADD") opcode = ADD;
        else if(opcodeStr == "SUB") opcode = SUB;
        else if(opcodeStr == "AND") opcode = AND;
        else if(opcodeStr == "OR") opcode = OR;
        else if(opcodeStr == "SLT") opcode = SLT;
        else opcode = MUL;


        result = (opcode <<26) | (rsNum << 21) | (rtNum << 16) | (rdNum << 11);

        

    }

    else if(opcodeStr  == "ADDI" || opcodeStr  == "SUBI" || opcodeStr  == "SLTI" )
    {
        string rt,rs,imm;
        ss >> rt >> rs >> imm;
        rt = trim(rt); rs = trim(rs); imm = trim(imm);
        rt.pop_back(); rs.pop_back();


        int rtNum = Reg[rt];
        int rsNum = Reg[rs];
        int immNum = stoi(imm);

        int opcode;
        if(opcodeStr == "ADDI") opcode = ADDI;
        else if(opcodeStr == "SUBI") opcode = SUBI;
        else SLTI;
        

        result = (opcode << 26) | (rsNum << 21 ) | (rtNum << 16) | (immNum & 0xFFFF);

    }

    else if(opcodeStr  == "LW" || opcodeStr  == "SW"){
        string rt,mem;
        ss >> rt >> mem;

        rt = trim(rt); rt.pop_back();
        size_t left_par = mem.find('(');
        size_t right_par = mem.find(')');
        string immStr = mem.substr(0,left_par);
        string rsStr = mem.substr(left_par + 1,right_par - left_par - 1);
        int rtNum = Reg[rt];
        int rsNum = Reg[rsStr];
        int immNum = stoi(immStr);
        int opcode = (opcodeStr == "LW") ? LW : SW;

        result = (opcode << 26) | (rsNum << 21 ) | (rtNum << 16) | (immNum & 0xFFFF);
    }

    else if(opcodeStr == "BEQZ" || opcodeStr == "BNEQZ")
    {
        string rs, label;
        ss >> rs >> label;
        rs = trim(rs); label = trim(label);
        rs.pop_back(); //Remove commmas
        

        int rsNum = Reg[rs];
        int offset = Label_Add[label] - (curr + 1);

        cout << offset <<"#" << curr<<"\n";

        int opcode = (opcodeStr == "BEQZ") ? BEQZ : BNEQZ;

        result = (opcode << 26) | (rsNum << 21) | (offset & 0xFFFF);

    }

    else if(opcodeStr == "JUMP" || opcodeStr == "JAL")
    {
        string addrStr;
        ss >> addrStr;
        addrStr = trim(addrStr);

        int address = 0;

   
        if (Label_Add.find(addrStr) != Label_Add.end()) {
            address = Label_Add[addrStr];
            } else {
         
            try {
              address = stoi(addrStr);
            } catch (...) {
             cerr << "❌ Error: Invalid jump address or label: '" << addrStr << "' in line: " << line << endl;
             exit(1);
            }
        }

        int opcode = (opcodeStr == "JUMP") ? JUMP : JAL;
        result = (opcode << 26) | (address & 0x3FFFFFF);
        cout <<address << "\n";
    }


    else if(opcodeStr == "JR")
    {
        string rs;
        ss >> rs;
        rs = trim(rs);
        int rsNum = Reg[rs];

        result = (JR << 26) | (rsNum << 21);
    }

    else if(opcodeStr == "HLT")
    {
        result = (HLT << 26);
    }

    return result;


}



int main()
{
    ifstream infile("input.asm");
    ofstream outfile("output.mem");

    if(!infile.is_open())
    {
        cerr << "Error: input.asm is not open\n";
        return 1;
    }

    detect(infile);

   
    for(int i = 0;i<instruction.size();i++){
        uint32_t machineCode = assembleInstruction(instruction[i],i);

        outfile << hex << setw(8) << setfill('0') << machineCode << "\n";

               
    }

    cout << "Assembling complete\n";
    return 0;
}
