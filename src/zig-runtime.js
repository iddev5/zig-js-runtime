let text_decoder = new TextDecoder;
let log_buf = "";

let uindex = 0;
let indices = [];
let values = [];
let value_map = {};

class MemoryBlock {
	constructor(mem, offset=0) {
		this.mem = mem;
		this.offset = offset;
	}

	slice(offset) {
		return new MemoryBlock(this.mem, offset);
	}

	getMemory() {
		return new DataView(this.mem, this.offset);
	}

	getU8(offset) {
		return this.getMemory().getUint8(offset, true);
	}

	getU32(offset) {
		return this.getMemory().getUint32(offset, true);
	}

	getU64(offset) {
		const ls = this.getU32(offset);
		const ms = this.getU32(offset + 4);

		return ls + ms * 4294967296;
	}

	getF64(offset) {
		return this.getMemory().getFloat64(offset, true);
	}

	getString(offset, len) {
		return text_decoder.decode(new Uint8Array(this.mem, offset, len));
	}

	setU8(offset, data) {
		this.getMemory().setUint8(offset, data, true);
	}

	setU32(offset, data) {
		this.getMemory().setUint32(offset, data, true);
	}

	setU64(offset, data) {
		this.getMemory().setUint32(offset, data, true);
		this.getMemory().setUint32(offset + 4, Math.floor(data / 4294967296), true);
	}

	setF64(offset, data) {
		this.getMemory().setFloat64(offset, data, true);
	}

	setString(offset, str) {
		const string = text_encoder.encode(str);
		const buffer = new Uint8Array(this.mem, offset, string.length);
		for (let i = 0; i < string.length; i += 1) {
			buffer[i] = string[i];
		}
	}
}

class ZObject {
	static write(block, data, type) {
		switch (type) {
			case "object": 
				block.setU8(0, 0); 
				block.setU64(8, data);
				break;
			case "number":
				block.setU8(0, 1);
				block.setF64(8, data);
				break;
			case "boolean":
				block.setU8(0, 2);
				block.setU8(8, data);
				break;
			case "string":
				block.setU8(0, 3);
				block.setU32(8, data.length);
				//block.setU64(16, data); // TODO
				break;
		}
	}

	static read(block, memory) {
		switch (block.getU8(0)) {
			case 0:
				return values[block.getU64(8)];
				break;
			case 1:
				return block.getF64(8);
				break;
			case 2:
				// TEST
				return Boolean(block.getU8(8));
				break;
			case 3:
				const len = block.getU32(8);
				const ptr = block.getU32(12);
				return memory.getString(ptr, len);
				break;
		}
	}
}

const zig = {
	wasm: undefined,
	buffer: undefined,

	init(wasm) {
		this.wasm = wasm;

		values = [];
		value_map = [];
		this.addValue(globalThis);
	},

	addValue(value) {
		value.__uindex = uindex;
		let idx = indices.pop();
		if (idx !== undefined) {
			values[idx] = value;
		} else {
			idx = values.push(value) - 1;
		}
		value_map[uindex] = idx;
		uindex += 1;
		return idx;
	},

	zigCreateMap() {
		return zig.addValue(new Map());
	},

	zigCreateArray() {
		return zig.addValue(new Array());
	},

	getProperty(prop, ret_ptr) {
		const type = typeof prop;
		switch (type) {
			case "object":
				prop = value_map[prop.__uindex];
				break;
		}

		let memory = new MemoryBlock(zig.wasm.exports.memory.buffer, ret_ptr);
		ZObject.write(memory, prop, type);
	},

	zigGetProperty(id, name, len, ret_ptr) {
		let memory = new MemoryBlock(zig.wasm.exports.memory.buffer);
		let prop = values[id][memory.getString(name, len)];
		zig.getProperty(prop, ret_ptr);
	},

	zigSetProperty(id, name, len, set_ptr) {
		let memory = new MemoryBlock(zig.wasm.exports.memory.buffer);
		values[id][memory.getString(name, len)] =
			ZObject.read(memory.slice(set_ptr), memory);
	},

	zigGetIndex(id, index, ret_ptr) {
		let prop = values[id][index];
		zig.getProperty(prop, ret_ptr);
	},

	zigSetIndex(id, index, set_ptr) {
		let memory = new MemoryBlock(zig.wasm.exports.memory.buffer);
		values[id][index] = ZObject.read(memory.slice(set_ptr), memory);
	},

	zigCleanupObject(id) {
		const idx = Number(id);
		delete value_map[values[idx].__uindex];
		delete values[idx];
		indices.push(idx);
	},

	zigFunctionCall(id, name, args, args_len) {

	},

	wzLogWrite(str, len) {
		let memory = new MemoryBlock(zig.wasm.exports.memory.buffer);
		log_buf += memory.getString(str, len);
	},

	wzLogFlush() {
		console.log(log_buf);
		log_buf = "";
	},

	wzPanic(str, len) {
		let memory = new MemoryBlock(zig.wasm.exports.memory.buffer);
		throw Error(memory.getString(str, len));
	},
};

export { zig };
